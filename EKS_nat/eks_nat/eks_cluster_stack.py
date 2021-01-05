from aws_cdk import core, aws_eks, aws_ec2


class Eks(core.Construct):
    def __init__(self, scope: core.Construct, id: str, cluster_configuration, vpc, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        self.cluster_configuration = cluster_configuration
        self.vpc = vpc
        
        def determine_cluster_size(self):
            if self.cluster_configuration['capacity_details'] == 'small':
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.BURSTABLE3, aws_ec2.InstanceSize.SMALL)
                instance_count = 3
            elif self.cluster_configuration['capacity_details'] == 'medium':
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.COMPUTE5, aws_ec2.InstanceSize.LARGE)
                instance_count = 3
            return { 'default_capacity': instance_count, 'default_capacity_instance': instance_details }
         
        capacity_details = determine_cluster_size(self)
     