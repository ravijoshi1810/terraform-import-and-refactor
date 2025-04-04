#!/bin/bash
# Input file to be processed
input_file="imported-alb-prod-docker-ericsson-crq00000082339.tf"
output_dir="updated-tf-files"
output_file="$output_dir/imported-alb-prod-docker-ericsson-crq00000082339.tf"

# Prompt user for LBName or unique identifier
LBName="docker"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Temporary files for sorting
lb_file=$(mktemp)
lb_listener_file=$(mktemp)
lb_target_group_file=$(mktemp)
lb_target_group_attachment_file=$(mktemp)

# Read the file and split resources into separate files
awk -v LBName="$LBName" '
BEGIN { resource_type = "" }
/^resource "aws_lb"/ {
    resource_type = "aws_lb"
    output = $0 "\n"
    next
}
/^resource "aws_lb_listener"/ {
    resource_type = "aws_lb_listener"
    output = $0 "\n"
    next
}
/^resource "aws_lb_target_group"/ {
    resource_type = "aws_lb_target_group"
    output = $0 "\n"
    next
}
/^resource "aws_lb_target_group_attachment"/ {
    resource_type = "aws_lb_target_group_attachment"
    output = $0 "\n"
    next
}
{
    if (resource_type != "") {
        output = output $0 "\n"
    }
}
/^\}/ {
    if (resource_type == "aws_lb") {
        print output >> "'"$lb_file"'"
    } else if (resource_type == "aws_lb_listener") {
        print output >> "'"$lb_listener_file"'"
    } else if (resource_type == "aws_lb_target_group") {
        print output >> "'"$lb_target_group_file"'"
    } else if (resource_type == "aws_lb_target_group_attachment") {
        print output >> "'"$lb_target_group_attachment_file"'"
    }
    resource_type = ""
    output = ""
}
' "$input_file"

# Function to remove tags_all section
remove_tags_all() {
    local file=$1

    awk '
    BEGIN { RS = ""; FS = "\n"; ORS = "\n\n" }
    {
        # Remove tags_all section
        while (match($0, /tags_all = {[^}]*\}/)) {
            $0 = substr($0, 1, RSTART-1) substr($0, RSTART+RLENGTH)
        }
        print $0
    }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Function to replace tags block
replace_tags() {
    local file=$1
    local resource_type=$2
    local LBName=$3

    awk -v resource_type="$resource_type" -v LBName="$LBName" '
    BEGIN { RS = ""; FS = "\n"; OFS = "\n" }
    {
        if (resource_type == "aws_lb") {
            gsub(/tags\s*=\s*\{[^}]*\}/, "tags = local." LBName "_lb_tags")
        }
        print $0
    }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Process each temporary file
remove_tags_all "$lb_file"


replace_tags "$lb_file" "aws_lb" "$LBName"


# Combine all the processed files into the output file
{
    echo "// Add locals for tags"
    echo "locals {"
    echo "  ${LBName}_lb_common_tags = {"
    echo "    // ADD COMMON TAGS HERE"
    echo "  }"
    echo "  ${LBName}_lb_specific_tags = {"
    echo "    // ADD LB SPECIFIC TAGS HERE"
    echo "  }"
    echo "  // Final LB tags"
    echo "  ${LBName}_lb_tags = merge(local.${LBName}_lb_common_tags, local.${LBName}_lb_specific_tags)"
    echo ""
    echo "}"

    echo "### AWS Load Balancer ###"
    if [ -s "$lb_file" ]; then
        cat "$lb_file"
        echo ""
    fi

    echo "### AWS Load Balancer Listener ###"
    if [ -s "$lb_listener_file" ]; then
        cat "$lb_listener_file"
        echo ""
    fi

    echo "### AWS Load Balancer Target Group ###"
    if [ -s "$lb_target_group_file" ]; then
        cat "$lb_target_group_file"
        echo ""
    fi

    echo "### AWS Load Balancer Target Group Attachment ###"
    if [ -s "$lb_target_group_attachment_file" ]; then
        cat "$lb_target_group_attachment_file"
    fi
} > "$output_file"

# Clean up temporary files
rm -f "$lb_file" "$lb_listener_file" "$lb_target_group_file" "$lb_target_group_attachment_file"

echo "Rearranged content saved to $output_file"

# Run terraform fmt and terraform validate
cd "$output_dir"
echo "Running terraform fmt..."
terraform fmt
echo "Running terraform validate..."
terraform validate
