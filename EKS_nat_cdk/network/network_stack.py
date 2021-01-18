from aws_cdk import core, aws_ec2

class NetworkStack(core.Stack):
    
    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)



        self.defaultVpc = aws_ec2.Vpc(self, "Default",
            cidr='10.0.0.0/24',
            nat_gateways=2,
            subnet_configuration=[
                aws_ec2.SubnetConfiguration(
                    name="public",
                    cidr_mask=27,
                    reserved=False,
                    subnet_type=aws_ec2.SubnetType.PUBLIC),
                aws_ec2.SubnetConfiguration(
                    name="private",
                    cidr_mask=27,
                    reserved=False,
                    subnet_type=aws_ec2.SubnetType.PRIVATE)
            ]
        )

        self.eksVpc = aws_ec2.Vpc(self, "EKSvpc",
            cidr='192.168.0.0/24',
            subnet_configuration=[
                aws_ec2.SubnetConfiguration(
                    name="private",
                    cidr_mask=26,
                    reserved=False,
                    subnet_type=aws_ec2.SubnetType.ISOLATED)
            ]
        )

        self.transitGw = aws_ec2.CfnTransitGateway(self, "DefaultTransitGw", 
            default_route_table_association="disable", 
        )

        self.tgAttachmentPrivate = aws_ec2.CfnTransitGatewayAttachment(self, "DefaultTGAttachment", 
            transit_gateway_id=self.transitGw.ref,
            vpc_id=self.defaultVpc.vpc_id,
            subnet_ids=[self.defaultVpc.private_subnets[0].subnet_id, self.defaultVpc.private_subnets[1].subnet_id],
            tags=None
        )
        self.tgAttachmentPrivate.add_depends_on(self.transitGw)

        self.tgAttachmentEks = aws_ec2.CfnTransitGatewayAttachment(self, "EksTGAttachment", 
            transit_gateway_id=self.transitGw.ref,
            vpc_id=self.eksVpc.vpc_id,
            subnet_ids=[self.eksVpc.isolated_subnets[0].subnet_id, self.eksVpc.isolated_subnets[1].subnet_id],
            tags=None           
        )
        self.tgAttachmentEks.add_depends_on(self.transitGw)

        isolatedSubnetRoutes = core.Construct(self, 'Isolated Subnet Routes')
        for (i, subnet) in enumerate(self.eksVpc.isolated_subnets):
            aws_ec2.CfnRoute(isolatedSubnetRoutes, 
                id=f"Default Route EKS {i}",
                route_table_id=subnet.route_table.route_table_id, 
                destination_cidr_block="0.0.0.0/0", 
                transit_gateway_id=self.transitGw.ref
                ).add_depends_on(self.tgAttachmentEks)


        privateSubnetRoutes = core.Construct(self, 'Private Subnet Routes')
        for (i, subnet) in enumerate(self.defaultVpc.private_subnets):
            aws_ec2.CfnRoute(privateSubnetRoutes, 
                id=f"Eks route defalt {i}", 
                route_table_id=subnet.route_table.route_table_id, 
                destination_cidr_block=self.eksVpc.vpc_cidr_block, 
                transit_gateway_id=self.transitGw.ref
                ).add_depends_on(self.tgAttachmentEks)


        publicSubnetRoutes = core.Construct(self, 'Public Subnet Routes')
        for (i, subnet) in enumerate(self.defaultVpc.public_subnets):
            aws_ec2.CfnRoute(publicSubnetRoutes, 
                id=f"Eks route defalt {i}", 
                route_table_id=subnet.route_table.route_table_id, 
                destination_cidr_block=self.eksVpc.vpc_cidr_block, 
                transit_gateway_id=self.transitGw.ref
                ).add_depends_on(self.tgAttachmentEks)



        self.transitGwRT = aws_ec2.CfnTransitGatewayRouteTable(self, 'transitGw Route Table',
            transit_gateway_id=self.transitGw.ref,
            tags=None
            )


        self.transitGwRoute = aws_ec2.CfnTransitGatewayRoute(self, 'transitGW Route',
            transit_gateway_route_table_id=self.transitGwRT.ref, 
            destination_cidr_block='0.0.0.0/0', 
            transit_gateway_attachment_id=self.tgAttachmentPrivate.ref)

        self.TGRouteTableAssociationDefaultVPC = aws_ec2.CfnTransitGatewayRouteTableAssociation(self, 'DefaultVPC Association',
            transit_gateway_attachment_id=self.tgAttachmentPrivate.ref, 
            transit_gateway_route_table_id=self.transitGwRoute.transit_gateway_route_table_id)

        self.TGRouteTablePropagationDefaultVPC = aws_ec2.CfnTransitGatewayRouteTablePropagation(self, 'DefaultVPC Propagation',
            transit_gateway_attachment_id=self.tgAttachmentPrivate.ref, 
            transit_gateway_route_table_id=self.transitGwRoute.transit_gateway_route_table_id)
        
        self.TGRouteTableAssociationEksVPC = aws_ec2.CfnTransitGatewayRouteTableAssociation(self, 'EksVPC Association',
            transit_gateway_attachment_id=self.tgAttachmentEks.ref, 
            transit_gateway_route_table_id=self.transitGwRoute.transit_gateway_route_table_id)

        self.TGRouteTablePropagationEksVPC = aws_ec2.CfnTransitGatewayRouteTablePropagation(self, 'EksVPC Propagation',
            transit_gateway_attachment_id=self.tgAttachmentEks.ref, 
            transit_gateway_route_table_id=self.transitGwRoute.transit_gateway_route_table_id)

