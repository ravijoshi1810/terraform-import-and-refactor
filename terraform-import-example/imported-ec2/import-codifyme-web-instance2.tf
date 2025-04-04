import {
  to = aws_instance.codifyme-instance
  id = "i-028015c8ff2e485f1"
} 
import {
  to = aws_ebs_volume.vol-0765af5e7f98e4ff2
  id = "vol-0765af5e7f98e4ff2"
}
import {
  to = aws_volume_attachment.vol-0765af5e7f98e4ff2
  id = "/dev/sdc:vol-0765af5e7f98e4ff2:i-028015c8ff2e485f1"
}
import {
  to = aws_ebs_volume.vol-008d72649b3ec8cd3
  id = "vol-008d72649b3ec8cd3"
}
import {
  to = aws_volume_attachment.vol-008d72649b3ec8cd3
  id = "/dev/xvde:vol-008d72649b3ec8cd3:i-028015c8ff2e485f1"
}
import {
  to = aws_ebs_volume.vol-0f0534d099b1fcff7
  id = "vol-0f0534d099b1fcff7"
}
import {
  to = aws_volume_attachment.vol-0f0534d099b1fcff7
  id = "/dev/xvdf:vol-0f0534d099b1fcff7:i-028015c8ff2e485f1"
}
import {
  to = aws_route53_record.codifyme-instance
  id = "Z08762823EE7SYDQFT5JF_codifyme-instance.437036372451.eu-west-1.abc.corp"
}