from aws_cdk import core, aws_ec2, aws_eks

class EksStack(core.Stack):
    
    def __init__(self, scope: core.Construct, id: str, vpc, eks_version=aws_eks.KubernetesVersion.V1_18, cluster_name=None, capacity_details='small', fargate_enabled=False, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        
        
        self.vpc = vpc

        self.eks_version = eks_version
        self.cluster_name = cluster_name
        self.capacity_details = capacity_details
        self.fargate_enabled = fargate_enabled



        self.cluster_config = {
            'eks_version': self.eks_version,
            'cluster_name': self.cluster_name,
            'capacity_details': self.capacity_details,
            'fargate_enabled': self.fargate_enabled
        }


        def determine_cluster_size(self):
            if self.cluster_config['capacity_details'] == 'small':
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.BURSTABLE3, aws_ec2.InstanceSize.SMALL)
                instance_count = 3
            elif self.cluster_config['capacity_details'] == 'medium':
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.COMPUTE5, aws_ec2.InstanceSize.LARGE)
                instance_count = 3
            elif self.cluster_config['capacity_details'] == 'large':
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.COMPUTE5, aws_ec2.InstanceSize.LARGE)
                instance_count = 6
            else:
                instance_details = aws_ec2.InstanceType.of(aws_ec2.InstanceClass.BURSTABLE3, aws_ec2.InstanceSize.SMALL)
                instance_count = 1
            return { 'default_capacity': instance_count, 'default_capacity_instance': instance_details }
         
        capacity_details = determine_cluster_size(self)


        




        self.cluster = aws_eks.Cluster(
            self, "EKSCluster",
            version = self.cluster_config['eks_version'],
            cluster_name = self.cluster_config['cluster_name'],
            vpc=vpc, 
            vpc_subnets=vpc.isolated_subnets,
            **capacity_details
            )

        # If fargate is enabled, create a fargate profile
        if self.cluster_config['fargate_enabled'] is True:
            self.cluster.add_fargate_profile(
                "FargateEnabled",
                selectors = [
                    aws_eks.Selector(
                        namespace = 'default',
                        labels = { 'fargate': 'enabled' }
                    )
                ]
            )