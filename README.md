# SmeshLogParser
Disclaimer:
**SmeshLogParser is an independent project developed by myself**

Please note that while this project is designed to work with the Windows Spacemesh applications, it remains an independent effort and is not an official product of the Spacemesh team.

For bug reports, suggestions, or contributions, feel free to ping me a DM on Discord

Functionality
-
Reads logs from go-spacemesh and returns a dashboard with the important bits. Can be adopted by changing the location of the logs.

Windows only at this point.

This version is mainly set up for the SMapp. If you need this for go-spacemesh, you will need to make sure you've set it up to capture logs. As go-spacemesh already creates a "spacemesh" folder within the %userprofile%, it's best to point it there for ease of use. 

Example of a powershell script to get go-spacemesh to capture logs:

```.\go-spacemesh --listen /ip4/0.0.0.0/tcp/7513 --config .\{configfolder}\config-metrics.json 2>&1 | Tee-Object -FilePath "C:\Users\{user}\Spacemesh\log.txt" -Append```

Once that is running, ensure logs are actually being captured. To be extra sure the -Append command is doing its job, run the script, CTRL+C to stop it and run again. You should have "Welcome to Spacemesh. Spacemesh full node is starting..." mentioned twice in the log.

Once that's OK, you can run the SmeshLogParser script to provide you with the information it's set to extract.

Please note that the parser will only return information that your logs currently have. If the necessary information on the logs isn't there, it defaults to a negative/false state.

What you will get is a window similar to the below:
![image](https://github.com/Dumraden/SmeshLogParser/assets/140160132/26074ee3-a0f3-4199-b37b-e5a8a6d9fec6)


There is a 5 second refresh for the overlay, if you wish to extend that, simply change the value in the ```Start-Sleep Seconds 5``` section to one of your liking.

Overlay information explained
-
1. App version is the go-spacemesh app version.
2. Generating Proof happens right at the beggining of the Gap Cycle (Start of the Proof Submission Window).
3. Looking for Proof includes both k2pow and the Nonce scan. Expect this to take anywhere from 1 to 12 hours.
4. Found Proof. Self explanatory really.
5. Proof Submitted. Your node was able to submit the proof to the network and is now eligible for rewards

6. Current Epoch: The current epoch we're in.
7. Rewards Expected Epoch: The Epoch you should be expecting to see rewards. 
8. Next Proof Submission Window - Tne next time your node becomes to start the process of generating a proof and submitting it begins.

9. Post Files initialized: The amount of files your node has been able to scan. Default is 2GB per file, so 2GB*1024 nets us a 2TiB post.
10. POST Corruption: Scans for any mentions of a corrupted POST. If there is one, the screen will turn red. In most occasions this calls for a verification of the POST using the tools from the Spacemesh team, but it's quite definitely a rebuild of the entire POST.

11. At the bottom you've got the NodeID so you can identify each node you have on. Especially useful for monitoring CLI nodes.





