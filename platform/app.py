#!/usr/bin/env python3

import aws_cdk as cdk

from platform.platform_stack import PlatformStack


app = cdk.App()
PlatformStack(app, "platform")

app.synth()
