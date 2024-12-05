# awsscripts
A collection of the helper shell scripts



ssm-env-parameters can be useful in a systemd service definition file to pull the app secrets into the application's context shell on startup
```
  ExecStart=/bin/bash -c '. /opt/www/application/aws/scripts/ssm-env-parameters.sh; /home/ubuntu/.nvm/versions/node/v16.16.0/bin/npm start'
```
