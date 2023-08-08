# SmeshLogParser
Disclaimer:
**SmeshLogParser is an independent project developed by myself**

Please note that while this project is designed to work with the Windows Spacemesh CLI node, it remains an independent effort and is not an official product of the Spacemesh team.

For bug reports, suggestions, or contributions, feel free to ping me a DM on Discord

Functionality
-
Reads logs from go-spacemesh and returns a dashboard with the important bits.

Windows only at this point.

This version is mainly set up for go-spacemesh, but you will need to make sure you've set it up to capture logs.

Example of a powershell script to get go-spacemesh to capture logs:

```.\go-spacemesh --listen /ip4/0.0.0.0/tcp/7513 --config .\Smesh1\config-metrics.json 2>&1 | Tee-Object -FilePath "C:\Smesh\Smesh1\log.txt" -Append```

Once that is running, ensure logs are actually being captured. To be extra sure the -Append command is doing its job, run the script, CTRL+C to stop it and run again. You should have "Welcome to Spacemesh. Spacemesh full node is starting..." mentioned twice in the log.

Once that's OK, you can run the SmeshLogParser script to provide you with the information it's set to extract.

Please note that the parser will only return information that your logs currently have. If the necessary information on the logs isn't there, it defaults to a negative/false state.

What you will get is a window similar to the below:
![image](https://github.com/Dumraden/SmeshLogParser/assets/140160132/06f9c706-a83d-4ce8-9f9c-29847f6f069f)

There is a 0.51 second refresh for the overlay, if you wish to extend that, simply change the value in the ```Start-Sleep -Seconds 0.51``` section to one of your liking.

Overlay information explained
-
1. App version is the go-spacemesh app version.
2. Synced: Shows whether the node is synced with the Spacemesh network.
3. Peers: The amount of nodes you're connected to.
4. Top Layer: The current top layer of the network
5. Synced Layer: The layer that you're node is synced on.
6. Verified layer: The layer the node has verified rewards for.
7. Generating Proof happens right at the beggining of the Gap Cycle (Start of the Proof Generation/Submission Window).
8. Looking for Proof includes both k2pow and the Nonce scan. This can take quite some time, depends on system specs as well as PoST Size/Nonce count.
9. Proof Submitted. Your node was able to submit the proof to the network and is now eligible for rewards
10. Found proof in PoST in: The total amount of time it took for your Node to find a Proof in the PoST. Anything below 10 hours is considered "safe".
   
11. Current Epoch: The current epoch we're in.
12. Rewards Expected Epoch: The Epoch you should be expecting to see rewards.
13. Next Proof Generation Window - Tne next time your node becomes to start the process of generating a proof and searching for it in the PoST
14. Next Proof Submission Window - Starts on the 11th hour of the 12 hour Cycle Gap. 

15. CPU Usage: Current CPU Usage (take it with a pinch of salt)
16. HDD Read Speed (live read speed. useful for Proof Generation)

17. Post Files initialized: The amount of files your node has been able to scan. Default is 2GB per file, so 2GB*1024 nets us a 2TiB post.
18. POST Corruption: Scans for any mentions of a corrupted POST. If there is one, the screen will turn red. In most occasions this calls for a verification of the POST using the tools from the Spacemesh team, but it's quite definitely a rebuild of the entire POST.

19. At the bottom you've got the NodeID so you can identify each node you have on.





