CarrierWave.configure do |config|
  if Rails.env.production?
    config.storage = :aws
    if ENV["AWS_BUCKET"]
      config.aws_bucket = ENV["AWS_BUCKET"]
    else
      config.aws_bucket = "shareyourbber.livre"
    end
  elsif (Rails.env.development? && Rails.application.secrets.aws_access_key_id.present?)
    config.storage = :aws
    config.aws_bucket =  "shareyourbber.livre"
  else
    config.storage = :file
    config.aws_bucket =  "shareyourbber.livre"
  end
  config.aws_acl    =  :public_read

  config.aws_credentials = {
    access_key_id:      Rails.application.secrets.aws_access_key_id,    # required
    secret_access_key:  Rails.application.secrets.aws_secret_access_key,    # required
    region: "sa-east-1"
  }
end
