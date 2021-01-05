from aws_cdk import core, aws_eks
from .eks_vpc_stack import VpcStack
from .eks_cluster_stack import Eks

class EksStack(core.Stack):
    
    def __init__(self, scope: core.Construct, id: str, 
    eks_version=aws_eks.KubernetesVersion.V1_17,
    cluster_name=None, 
    capacity_details='small',
    fargate_enabled=False,
    **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        self.eks_version = eks_version
        self.cluster_name = cluster_name
        self.capacity_details = capacity_details
        self.fargate_enabled = fargate_enabled
        
        # Setting up the VPC
        vpc = VpcStack(self, "Vpc")
        
        config_dict = {
            'eks_version': self.eks_version,
            'cluster_name': self.cluster_name,
            'capacity_details': self.capacity_details,
            'fargate_enabled': self.fargate_enabled
        }
        
        #Setting up the EKS cluster
        cluster = Eks(self, "Base", cluster_configuration=config_dict, vpc=vpc.vpc)
        
        