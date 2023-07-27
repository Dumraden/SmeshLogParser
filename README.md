# SmeshLogParser
Reads logs from SMapp, or go-spacemesh and returns a dashboard with the important bits.

Windows only at this point.

This version is mainly set up for the SMapp. If you need this for go-spacemesh, you will need to make sure you've set it up to capture logs. As go-spacemesh already creates a "spacemesh" folder within the %userprofile%, it's best to point it there for ease of use. 

Example of a powershell script to get go-spacemesh to capture logs:

```.\go-spacemesh --listen /ip4/0.0.0.0/tcp/7513 --config .\{configfolder}\config-metrics.json 2>&1 | Tee-Object -FilePath "C:\Users\user\Spacemesh\log.txt" -Append```

Once that is running, ensure logs are actually being captured. To be extra sure the -Append command is doing its job, run the script, CTRL+C to stop it and run again. You should have "Welcome to Spacemesh. Spacemesh full node is starting..." mentioned twice in the log.

Once that's OK, you can run the SmeshLogParser to provide you with the information it's set to extract.
