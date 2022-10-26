terraform{
    required_version = ">= 0.12.24"
    
    backend "s3" {
      bucket = "harry-bosch"
      key    = "harry-bosch.tfstate"
      region = "ap-south-1"
    }
    
}

provider "random" {}

provider "aws" {
    region = "ap-south-1"
}
