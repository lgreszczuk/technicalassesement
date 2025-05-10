# technicalassesement
Awareson TA

# planned repo structure

azure-app-db-deploy/
│
├── app/                        # Python web app code
│   ├── main.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
│
├── terraform/                  # Terraform code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .github/workflows/         # GitHub Actions deployment workflow
│   └── deploy.yml
│
└── README.md