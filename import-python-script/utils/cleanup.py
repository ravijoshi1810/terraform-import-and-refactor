import re
import sys
from loguru import logger
import os
import subprocess

# Define the RESOURCE_CLEANUP dictionary with patterns properly escaped
RESOURCE_CLEANUP = {
    "global": ["null", "= {}"],
    "multiline_pattern": [
        r"target_failover\s*\{\s*\n\s*\}",
        r"target_health_state\s*\{\s*\n\s*\}",
    ],
    "aws_instance": ["= 0", "= \[\]", "ipv6_address_count", '= "lt-'],
    "aws_rds_cluster": [
        "= 0",
        "= \[\]",
    ],
    "aws_rds_cluster_instance": [
        "= 0",
        "= \[\]",
    ],
    "aws_db_instance": [
        "= 0",
        "= \[\]",
    ],
    "aws_kms_key": [
        "= 0",
        "= \[\]",
        "replicate_source_db",
    ],
    "aws_route53_record": [
        "multivalue_answer_routing_policy",
        "= 0",
        "= \[\]",
    ],
    "aws_ebs_volume": ["= 0"],
    "aws_eks_node_group": ["= 0", "= \[\]", "node_group_name_prefix", '= "lt-'],
    "aws_security_group": ["name_prefix"],
    "aws_launch_template": [
        "name_prefix",
        "= 0",
        "= \[\]",
    ],
    "aws_lb_listener": [
        "= 0",
        "= \[\]",
    ],
    "aws_lb": [
        "subnets ",
        "name_prefix",
    ],
    "aws_lb_target_group": ["= 0"],
    "aws_autoscaling_group": ["= 0", "= \[\]", "availability_zones", "name_prefix"],
    "aws_emr_cluster": ["subnet_id "]
}


def remove_global_lines(tf_file, list_to_cleanup):
    output_file = tf_file  # f"{tf_file}-global-cleanup.tf"
    logger.info(f"Removing lines containing following items: {list_to_cleanup}")

    with open(tf_file, "r") as readfile:
        lines = readfile.readlines()
        filtered_lines = []

        for line in lines:
            if "duration = 0" in line: # Skip the 0 value for duration for aws_lb_listener
                filtered_lines.append(line)
                continue

            if "weight = 0" in line: # Skip the 0 value for weight for aws_lb_listener
                filtered_lines.append(line)
                continue

            if any(element in line for element in list_to_cleanup):
                # If 'Condition' is in the line and '= {}' is one of the elements, do not remove it.
                # Special rule for aws_iam_role properties assume_role_policy of jsonencode block.
                if "= {}" in line and "Condition" in line:
                    filtered_lines.append(line)
                
                # Handle null sensitive value for kerboreos auth in EMR cluster
                if any(keyword in line for keyword in ["ad_domain_join_password", "ad_domain_join_user", "cross_realm_trust_principal_password", "kdc_admin_password"]):
                    filtered_lines.append(line)
                continue
            
            filtered_lines.append(line)

    with open(output_file, "w") as write_file:
        write_file.writelines(filtered_lines)

    logger.info(f"Generated intermediate file to process: {output_file}")
    return output_file


def remove_multiline(file, patterns):
    with open(file, "r") as readfile:
        content = readfile.read()

        for pattern in patterns:
            matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
            # Remove the matches from the content
            content = re.sub(pattern, "", content, flags=re.MULTILINE | re.DOTALL)

    with open(file, "w") as writefile:
        writefile.write(content)


def should_remove_line(line, resource_type, custom_pattern=[]):
    """
    Determine if a line should be removed based on the resource type and global patterns.
    """
    if not custom_pattern:
        patterns = RESOURCE_CLEANUP.get(resource_type, [])
    else:
        patterns = custom_pattern

    for pattern in patterns:
        if "min_size" in line and resource_type in ("aws_autoscaling_group", "aws_eks_node_group"):  # for EKS Cluster aws_autoscaling_group, aws_eks_node_group
            return False
        if re.search(pattern, line):
            return True
    return False


def process_terraform_plan(input_file):
    with open(input_file, "r") as file:
        lines = file.readlines()

    new_lines = []
    in_resource_block = False
    current_resource_type = None

    # Special case ebs_volume Cleanup, Removing iops when type is gp2
    is_iops_set = False
    is_gp2_set = False

    for line in lines:
        # Check if the line starts a new resource block
        resource_block_match = re.match(r'\s*resource\s+"(\w+)"\s+"[^"]+"\s+{', line)
        if resource_block_match:
            in_resource_block = True
            current_resource_type = resource_block_match.group(1)

            new_lines.append(line)
            continue

        # Check if the line ends a resource block
        if in_resource_block and re.match(r"\s*}$\n#", line):
            in_resource_block = False
            current_resource_type = None
            new_lines.append(line)
            continue

        # Process lines within a resource block
        if in_resource_block and current_resource_type:
            if current_resource_type == "aws_ebs_volume":  # EDGE case for removing iops when type is gp2
                if "iops" in line:
                    is_iops_set = True
                    get_iops_line = line
                if "gp2" in line:
                    is_gp2_set = True
                if is_gp2_set and is_iops_set:
                    new_lines.remove(get_iops_line)
                    is_iops_set = False
                    is_gp2_set = False


            if current_resource_type == "aws_lb_listener":
                if "duration = 0" in line:
                    logger.error(f"duration value is set to be 1 :- Please verify before apply")
                    line = 'duration      = 1 # Changed to 1 from 0\n'

            if current_resource_type == "aws_lb_listener":
                if "weight = 0" in line:
                    logger.error(f"weight value is set to be 1 :- Please verify before apply")
                    line = 'weight      = 1 # Changed to 1 from 0\n'

            if current_resource_type == "aws_db_option_group": #Special Case for Jsonencode Skipping decimal in version number fix
                if "jsonencode(8)" in line:
                    line = 'major_engine_version      = "8.0"\n'
            if should_remove_line(line, current_resource_type):
                continue
        new_lines.append(line)

    # Write the cleaned content to a new file
    with open(input_file, "w") as new_file:
        new_file.writelines(new_lines)

    # logger.info(f"Cleanup Resources with Patterns: {RESOURCE_CLEANUP}")
    logger.info(f"Generated Cleaned up File: {input_file}")
    
    
#To remove all the tag_all block below def function is created
def tag_all_clean_tf_file(file_path):
    try:
        # Read the content of the .tf file
        with open(file_path, 'r') as file:
            tf_content = file.read()
        
        # Regular expression to match tags_all block
        tags_all_pattern = re.compile(r'tags_all\s*=\s*\{[^\}]*\}', re.DOTALL)
        
        # Substitute the found patterns with an empty string
        cleaned_content = tags_all_pattern.sub('', tf_content)
        
        # Write the cleaned content back to the .tf file
        with open(file_path, 'w') as file:
            file.write(cleaned_content)
        
        #print(f'Successfully cleaned and updated the file: {file_path}')
    
    except Exception as e:
        print(f'An error occurred: {e}')


# to comment out cpu options and credit specification below function is defined

def comment_out_cpu_and_credit(file_path):
    try:
        
        with open(file_path, 'r') as file:
            tf_content = file.read()

        cpu_options_pattern = re.compile(r'(\s*cpu_options\s*\{[^}]*\})', re.DOTALL)
        
    
        if cpu_options_pattern.search(tf_content):
            tf_content = cpu_options_pattern.sub(lambda match: '# ' + '\n# '.join(match.group(0).split('\n')), tf_content)
            

        
        credit_specification_pattern = re.compile(r'(\s*credit_specification\s*\{[^}]*\})', re.DOTALL)
        
        if credit_specification_pattern.search(tf_content):
            tf_content = credit_specification_pattern.sub(lambda match: '# ' + '\n# '.join(match.group(0).split('\n')), tf_content)

        with open(file_path, 'w') as file:
            file.write(tf_content)
            
    except Exception as e:
        print(f'An error occurred while commenting out cpu_options and credit_specification blocks: {e}')

        
def remove_ebs_block_device(file_path):
    try:
        # Read the content of the .tf file
        with open(file_path, 'r') as file:
            tf_content = file.read()
        
        # Regular expression to match ebs_block_device block
        ebs_block_device_pattern = re.compile(r'(\s*ebs_block_device\s*\{(?:[^{}]*|\{(?:[^{}]*|\{[^{}]*\})*\})*\})', re.DOTALL)
        
        # Substitute the found patterns with an empty string
        cleaned_content = ebs_block_device_pattern.sub('', tf_content)
        
        # Write the cleaned content back to the .tf file
        with open(file_path, 'w') as file:
            file.write(cleaned_content)
        
        print(f'Successfully removed ebs_block_device blocks and updated the file: {file_path}')
    
    except Exception as e:
        print(f'An error occurred: {e}')

def comment_out_kerberos_attributes(file_path):
    try:
        
        with open(file_path, 'r') as file:
            tf_content = file.read()

        kerberos_chnages = re.compile(r'(\s*kerberos_attributes\s*\{(?:[^{}]*|\{(?:[^{}]*|\{[^{}]*\})*\})*\})', re.DOTALL)        
    
        if kerberos_chnages.search(tf_content):
            tf_content = kerberos_chnages.sub(lambda match: '# ' + '\n# '.join(match.group(0).split('\n')), tf_content)
            print('kerberos_attributes block not found.')

        with open(file_path, 'w') as file:
            file.write(tf_content)
        
        print(f'Successfully commented out kerberos_attributes blocks in the file: {file_path}')
    
    except Exception as e:
        print(f'An error occurred while commenting out kerberos_attributes: {e}')

def cleanup_tf_plan_file(input_tf_file):

    # Process the Global defaults vaules
    level1_cleanup_file = remove_global_lines(input_tf_file, RESOURCE_CLEANUP["global"])

    # Process resource Specific Blocks
    process_terraform_plan(level1_cleanup_file)
    remove_multiline(input_tf_file, RESOURCE_CLEANUP["multiline_pattern"])
    tag_all_clean_tf_file(input_tf_file)
    comment_out_cpu_and_credit(input_tf_file)
    remove_ebs_block_device(input_tf_file)
    comment_out_kerberos_attributes(input_tf_file)
