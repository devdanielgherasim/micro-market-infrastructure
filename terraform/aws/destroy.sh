#!/bin/bash

# Initialize Terraform with environment-specific backend configuration
terraform init \
  -backend-config="bucket=terraform-microservices1691715-state" \
  -backend-config="key=environments/dev/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Destroy Terraform resources with environment-specific variables
terraform destroy --var-file=./tfvars_files/dev.tfvars \
  --var access_key="ASIA4JNTFFPJ4JOD2VZ6" \
  --var secret_key="VuTEqWiD9O/+XlxnA9vYUJxyhUa4sn7esXeqbZZX" \
  --var session_token="IQoJb3JpZ2luX2VjEFkaCXVzLXdlc3QtMiJHMEUCIHVZv1izUETjj6HXvOtRuzAztHLLr9h4C22zhKFk4ug3AiEA7JLap42K5hvKXO2sTvMPIlYOPFguDOCsd3weVBifqpYqwgIIMhABGgw4NDQ4NzM2NzM2ODMiDAv0cNB3Ch1+Lh7Y0SqfAhLKlWbmRTfUpO1IcSKodznCccupLOtKPhBPt1fOhojQ4dPh76SI/J90dyZHhHe8lwWSHU8cdxy7EB6IHUFEETrEZ44Z9XmV+2f5LXNtM9AThLvuunTL/RWCICrQl478dLWKekHgu+bEtmKcpxaH4LJnoQabhLiV0/gTlEEtu+XIx3c61ZmRCToGROxkuku3PokgfEtPCiaGDGaesqZNlKSqzIMCra2iVJUy2rUEXoxnrNkmBzfLHT7V7GpMBnu/wNUCUuiqat9hj14tDXYlSIQY8xkPzhDPPVRvspi6mswoHtG8y/qHO/HaArbPT9L4ygoL+JOdNCclwzkpKanT77XHlhK9oJCCTxc/eEYEivwXxj666CN37++IY7C561+aMJ79gcIGOp0BFnXHfYqefStQdD2bHtP30Zoa+d0bdDJ/SfDChkyQEWDD47YtajCC82FCD1MTq29lDTg3bPQ1LygeH/UeD/AxQR+7EmG+11jJMY0Iz7bYZgKUyLXXhbBjkyCfL50ywwIIHpJoaEst+SXqaRQLbHSk3Zl6DKHbNswWCBzGGQEM+JJSk8ru4DWzZwMM6UXVsXoBWYCr3IOkWTRgKFtB3A=="

# terraform force-unlock <LOCK_ID>
