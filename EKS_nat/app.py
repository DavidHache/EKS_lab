#!/usr/bin/env python3

from aws_cdk import core

from eks_nat.eks_stack import EksStack



# Cluster name: If none, will autogenerate
cluster_name = "ekslabcluster" 
# Capacity details: Cluster size of small/med/large
capacity_details = "small"


app = core.App()

EksStack(app, "eks-nat", capacity_details=capacity_details, cluster_name=cluster_name)


app.synth()
