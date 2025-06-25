# TitlelessWindows - Remove Windows11 title bars

This PowerShell script overrides the window style of **all** windows to remove the title bar, using the WinAPI to constantly monitor.  
Please note that this script only works with standard Windows 11 title bars and might create unwanted side effects with windows that use a custom title bar.  

Before:  
![Title bar visible](https://github.com/akkiirah/TitlelessWindows/assets/46369555/fa65c77d-c83c-4a43-9338-9f7e20102ca9)

After:  
![Title bar invisible](https://github.com/akkiirah/TitlelessWindows/assets/46369555/d06cff2d-a121-43a1-a098-0354416e1fbb)

I want to address that I'm not an expert programmer, nor do I have much experience in scripting with PowerShell.  
If you want to improve my code, feel free to do so!  
Since I've been wanting to disable the title bar for a while now, I hacked together something that seems to work, at least for me.

-----

### Prerequisites  
- PowerShell
- Any kind of text editor.
- Administrator rights on your user.
- A burning desire to delete title bars.

-----

### Installation
- Download the ZIP file and unpack its contents to a location of your choice.
- Open the `DeleteTitlebar.bat` file with the text editor of your choice and change `C:\Users\akkiirah\.glaze-wm\scripts\Deletetitle bar.ps1` to the path where you unpacked the files.

> This current version disables Window borders to perfectly cut the title bar.  
> If you want to have a border in exchange for an about 2-3px thick title bar,  
> open the ps1 file in any texteditor and change `$styleToRemove = 0x00C00000 -bor 0x00040000` to `$styleToRemove = 0x00C00000`  
> Save the file and continue.

-----

### How to use:
- Rightclick the Bat file and create a shortcut.
- Rightclick that shortcut, go to Properties.
- Under the “Shortcut” tab, change the “Run” dropdown to “Minimized". This will ensure that no cmd prompt will show up.
- If don't want to remove the titlebar for certain windows, you can just add the process name to the `ExcludedProcesses.txt` file.
- You can now simply run the created shortcut, which will remove all standard Windows 11 title bars.  

-----

### One more tip:
> This is for if you haven't changed `$styleToRemove` during the installation part!

If you're running GlazeWM with GAPS, deleting `WS_BORDER` seems to make all standard window containers not adjust acording to your set gap.  
To fix this, I apply the window rule to resize borders left, right and bottom minus your gap size and match it to every process.  
However you can also adjust the `match_process_name` to the windows that are making issues. I was to lazy for that so far.  

```yaml
  - command: 'resize borders 0px [your gap+1]px [your gap+1]px [your gap+1]px'
    match_process_name: '.*'
```
-----

### TODO:
- ~~Find a way to supress opening a powershell window when running the script.~~
- ~~Let the script run in the background and update the title bar of newly opend windows automatically.~~
- ~~Find a way to completly hide the title bar. No single pixel shall live.~~
- Find a way to restore or create a custom border.
- ~~find a way to subscribe to window creation/style change events.~~
-----

## License

This project is licensed under JNK 1.1 - an Anti-Capitalist, Share-Alike, Post-Open-Source license.

Use it, remix it, break it, rebuild it, make something your own and share it with the world.  
Just don’t sell it. Don’t lock it behind paywalls. Don’t wrap it in ads, NFTs, AI scraping, or subscription garbage.  

If you extend or modify this work, release your version under the same license.  
Keep it free, keep it open, and link back to the source.

This license exists to protect a space where creative work stays public and freely shared,  
instead of getting buried in products or turned into someone’s revenue stream.

See [LICENSE](LICENSE) for full details.
