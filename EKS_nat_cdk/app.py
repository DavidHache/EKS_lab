#!/usr/bin/env python3

from aws_cdk import core
from network.network_stack import NetworkStack
from eks.eks_stack import EksStack


app = core.App()
network = NetworkStack(app, "Network")
eks = EksStack(app, "EKS", vpc=network.eksVpc)



app.synth()
