#!/usr/bin/env python3

# cdk: 1.77.0

from aws_cdk import (
    aws_ec2,
    core
)

from os import getenv

class VpcStack(core.Stack):
    
    def __init__(self, scope: core.Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # This resource alone will create a private/public subnet in each AZ as well as nat/internet gateway(s)
        self.vpc = aws_ec2.Vpc(self, "EKSvpc",
            cidr='10.0.0.0/22',
            nat_gateways=2,
            subnet_configuration=[
                aws_ec2.SubnetConfiguration(
                    name="public",
                    cidr_mask=27,
                    reserved=False,
                    subnet_type=aws_ec2.SubnetType.PUBLIC),
                aws_ec2.SubnetConfiguration(
                    name="private",
                    cidr_mask=24,
                    reserved=False,
                    subnet_type=aws_ec2.SubnetType.PRIVATE)
            ]
        )
        
        

