function Get-AzAppGatewayDiagram {
    <#
.SYNOPSIS
Generates a Mermaid diagram for an Azure Application Gateway.

.DESCRIPTION
The Get-AzAppGatewayDiagram function generates a Mermaid diagram representing the configuration of an Azure Application Gateway. The diagram includes information about frontend IPs, HTTP listeners, SSL certificates, request routing rules, backend address pools, backend HTTP settings, URL path maps, and rewrite rule sets associated with the Application Gateway.

.PARAMETER AppGatewayName
The name of the Application Gateway.

.PARAMETER ResourceGroupName
The name of the Resource Group where the Application Gateway is located.

.PARAMETER Hostnames
An array of hostnames used to filter the diagram. If specified, only the listeners with matching hostnames will be included in the diagram. If not specified, all hostnames associated with the Application Gateway will be considered.

.PARAMETER GraphDirection
The direction of the Mermaid diagram. Valid values are 'TB' (Top-Bottom, default), 'BT' (Bottom-Top), 'LR' (Left-Right), and 'RL' (Right-Left).

.EXAMPLE
PS C:\> Get-AzAppGatewayDiagram -AppGatewayName "MyAppGateway" -ResourceGroupName "MyResourceGroup"

Generates a Mermaid diagram for the Application Gateway named "MyAppGateway" in the "MyResourceGroup" Resource Group.

.EXAMPLE
PS C:\> Get-AzAppGatewayDiagram -AppGatewayName "MyAppGateway" -ResourceGroupName "MyResourceGroup" -Hostnames "app.example.com", "api.example.com"

Generates a Mermaid diagram for the Application Gateway named "MyAppGateway" in the "MyResourceGroup" Resource Group, including only the listeners associated with the specified hostnames ("app.example.com" and "api.example.com").

.INPUTS
None. You cannot pipe objects to Get-AzAppGatewayDiagram.

.OUTPUTS
[PSCustomObject]
The function returns a custom object with the following property:
- MermaidMarkdown: A string containing the Mermaid diagram representation of the Application Gateway configuration.

.NOTES
- The function requires the Az PowerShell module to be installed. You can install it using the Install-Module cmdlet.
- Mermaid is a simple markdown-like script language for generating charts from text descriptions. For more information about Mermaid, visit https://mermaid-js.github.io/mermaid/.

.LINK
https://docs.microsoft.com/en-us/azure/application-gateway/overview
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Provide the name of the Application Gateway.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppGatewayName,
        
        [Parameter(Mandatory = $True, HelpMessage = "Provide the name of the Resource Group where the Application Gateway is located.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceGroupName,

        [Parameter(HelpMessage = "Provide hostnames to filter on, or leave blank to use all hostnames.")]
        [string[]]
        $Hostnames = "All",

        [Parameter(HelpMessage = "Provide graph direction. Default is Top-Bottom (TB).")]
        [string]
        $GraphDirection = 'TB'
    )
    begin {
        try {
            $AppGateway = Get-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $ResourceGroupName
        }
        catch {
            Write-Error "Failed to find Application Gateway with name '$AppGatewayName' in resource group '$ResourceGroupName'."
            return
        }
        $Diagram = [MermaidDiagram]::new($GraphDirection)
        If ($Hostnames -eq "All") {
            $Hostnames = $AppGateway.HttpListeners.Hostname | Select-Object -Unique
        }
    }
    
    process {
        foreach ($Hostname in $Hostnames) {
            $Listeners = $AppGateway.HttpListeners | Where-Object { $_.Hostname -eq $Hostname }
            foreach ($Listener in $Listeners) {

                $ListenerNode = [MermaidNode]::new("listener_$($Listener.Name)", "Listener: $($Listener.Name)<br>Hostname: $($Hostname)<br>Port: $($Listener.FrontendPort.Id.Split('_')[-1])<br>Protocol: $($Listener.Protocol.ToUpper())]")
                $Diagram.AddNode($ListenerNode)

                if ($Listener.FirewallPolicy) {
                    $PolicyName = $Listener.FirewallPolicy.Id.Split('/')[-1]
                    $PolicyResourceGroupName = $Listener.FirewallPolicy.Id.Split('/')[4]
                    $WafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName $PolicyResourceGroupName

                    $WafPolicyNode = [MermaidNode]::new("wafpolicy_$($WafPolicy.Name)", "WAF policy: $($WafPolicy.Name)")
                    $Diagram.AddNode($WafPolicyNode)
                    $Diagram.AddEdge($WafPolicyNode.Name, $ListenerNode.Name)
                }
                elseif ($AppGateway.FirewallPolicy) {
                    $PolicyName = $AppGateway.FirewallPolicy.Id.Split('/')[-1]
                    $PolicyResourceGroupName = $AppGateway.FirewallPolicy.Id.Split('/')[4]
                    $WafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName $PolicyResourceGroupName

                    $WafPolicyNode = [MermaidNode]::new("wafpolicy_$($WafPolicy.Name)", "WAF policy (gateway default): $($WafPolicy.Name)")
                    $Diagram.AddNode($WafPolicyNode)
                    $Diagram.AddEdge($WafPolicyNode.Name, $ListenerNode.Name)
                }

                $FrontendIpConfiguration = $AppGateway.FrontendIPConfigurations | Where-Object Id -eq $Listener.FrontendIpConfiguration.Id
                $FrontendIpConfigurationNode = [MermaidNode]::new("frontendipconfiguration_$($FrontendIpConfiguration.Name)", "Frontend IP: $($FrontendIpConfiguration.Name)$(If($FrontendIpConfiguration.PrivateIpAddress){"<br>Private IP: $($FrontendIpConfiguration.PrivateIpAddress)"})")
                $Diagram.AddNode($FrontendIpConfigurationNode)
                $Diagram.AddEdge($FrontendIpConfigurationNode.Name, $ListenerNode.Name)

                If ($FrontendIpConfiguration.PublicIpAddress) {
                    $PublicIpAddressName = $FrontendIpConfiguration.PublicIpAddress.Id.Split('/')[-1]
                    $PublicIpAddressResourceGroupName = $FrontendIpConfiguration.PublicIpAddress.Id.Split('/')[4]
                    $PublicIpAddress = Get-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $PublicIpAddressResourceGroupName

                    $PublicIpAddressNode = [MermaidNode]::new("publicipaddress_$($PublicIpAddress.Name)", "[Public IP Address: $($PublicIpAddress.Name)<br>$($PublicIpAddress.IpAddress)]")
                    $Diagram.AddNode($PublicIpAddressNode)
                    $Diagram.AddEdge($PublicIpAddressNode.Name, $FrontendIpConfigurationNode.Name)
                }
                
                if ($Listener.Protocol -eq 'Https') {
                    $SslCert = $AppGateway.SslCertificates | Where-Object Id -eq $Listener.SslCertificate.Id
                    $SslCertNode = [MermaidNode]::new("sslcert_$($SslCert.Name)", "SSL Cert: $($SslCert.Name)")
                    $Diagram.AddNode($SslCertNode)
                    $Diagram.AddEdge($SslCertNode.Name, $ListenerNode.Name)

                    If ($SslCert.KeyVaultSecretId) {
                        $KeyVaultCertificateId = $SslCert.KeyVaultSecretId.Replace('secrets', 'certificates')
                        $KeyVaultCertificateName = $KeyVaultCertificateId.Split('/')[4]
                        $KeyVaultName = $KeyVaultCertificateId.Split('/')[2].Split('.')[0]

                        $KeyVaultCertificateNode = [MermaidNode]::new("keyvaultcert_$($KeyVaultCertificateName)", "Key Vault Certificate: $KeyVaultCertificateName<br>Key Vault: $KeyVaultName")
                        $Diagram.AddNode($KeyVaultCertificateNode)
                        $Diagram.AddEdge($KeyVaultCertificateNode.Name, $SslCertNode).Name
                    }
                }

                $Rule = $AppGateway.RequestRoutingRules | Where-Object { $_.HttpListener.Id -eq $Listener.Id }

                $RuleNode = [MermaidNode]::new("rule_$($Rule.Name)", "Request Routing Rule: $($Rule.Name)")
                $Diagram.AddEdge($ListenerNode.Name, $RuleNode.Name)

                if ($Rule.UrlPathMap.Id) {
                    $UrlPathMap = $AppGateway.UrlPathMaps | Where-Object Id -eq $Rule.UrlPathMap.Id
                    Foreach ($PathRule in $UrlPathMap.PathRules) {

                        $UrlPathMapNode = [MermaidNode]::new("urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name)", "Path Rule: $($PathRule.Name)")
                        $Diagram.AddEdge($RuleNode.Name, $UrlPathMapNode.Name)
                        
                        If ($PathRule.BackendAddressPool) {
                            $BackendAddressPool = $AppGateway.BackendAddressPools | Where-Object Id -eq $PathRule.BackendAddressPool.Id
                            $Backends = $BackendAddressPool.BackendAddresses | ForEach-Object {
                                If ($_.Fqdn) {
                                    $_.Fqdn
                                }
                                elseIf ($_.IpAddress) {
                                    $_.IpAddress
                                }
                                else {
                                    "No targets"
                                }
                            }

                            $BackendAddressPoolNode = [MermaidNode]::new("backendaddresspool_$($BackendAddressPool.Name)", "Backend Address Pool: $($BackendAddressPool.Name)<br>Targets:<br>$($Backends -join "<br>")")
                            $Diagram.AddEdge($UrlPathMapNode.Name, $BackendAddressPoolNode.Name)
                            
                            $BackendHttpSetting = $AppGateway.BackendHttpSettingsCollection | Where-Object Id -eq $PathRule.BackendHttpSettings.Id
                            $BackendHttpSettingNode = [MermaidNode]::new("backendhttpsetting_$($BackendHttpSetting.Name)", "Backend HTTP Setting: $($BackendHttpSetting.Name)")
                            $Diagram.AddEdge($UrlPathMapNode.Name, $BackendHttpSettingNode.Name)
                        }
                        
                        If ($PathRule.RewriteRuleSet) {
                            $RewriteRuleSet = $AppGateway.RewriteRuleSets | Where-Object Id -eq $PathRule.RewriteRuleSet.Id
                            $RewriteRuleSetNode = [MermaidNode]::new("rewriteruleset_$($RewriteRuleSet.Name)", "Rewrite Rule Set: $($RewriteRuleSet.Name)")
                            $Diagram.AddEdge($UrlPathMapNode.Name, $RewriteRuleSetNode.Name)
                        }

                        $RedirectConfiguration = $AppGateway.RedirectConfigurations | Where-Object Id -eq $($AppGateway.Id + "/redirectConfigurations/" + $Rule.Name + "_" + $PathRule.Name)
                        If ($RedirectConfiguration.TargetUrl) {
                            $RedirectConfigurationNode = [MermaidNode]::new("redirectconfiguration_$($RedirectConfiguration.Name)", "External URL: $($RedirectConfiguration.TargetUrl)")
                            $Diagram.AddEdge($UrlPathMapNode.Name, $RedirectConfigurationNode.Name)
                        }
                        elseif ($RedirectConfiguration.TargetListener) {
                            $Diagram.AddEdge($UrlPathMapNode.Name, "listener_$($RedirectConfiguration.TargetListener.Id.Split('/')[-1])")
                        }
                    }   
                }

                $RedirectConfiguration = $AppGateway.RedirectConfigurations | Where-Object Id -eq $($AppGateway.Id + "/redirectConfigurations/" + $Rule.Name)
                If ($RedirectConfiguration) {
                    If ($RedirectConfiguration.TargetUrl) {
                        $RedirectConfigurationNode = [MermaidNode]::new("redirectconfiguration_$($RedirectConfiguration.Name)", "External URL: $($RedirectConfiguration.TargetUrl)")
                        $Diagram.AddEdge($RuleNode.Name, $RedirectConfigurationNode.Name)
                    }
                    Else {
                        $Diagram.AddEdge($RuleNode.Name, "listener_$($RedirectConfiguration.TargetListener.Id.Split('/')[-1])")
                    }  
                }
    
                If ($Rule.BackendAddressPool) {    
                    $BackendAddressPool = $AppGateway.BackendAddressPools | Where-Object Id -eq $Rule.BackendAddressPool.Id
                    $Backends = $BackendAddressPool.BackendAddresses | ForEach-Object {
                        If ($_.Fqdn) {
                            $_.Fqdn
                        }
                        elseIf ($_.IpAddress) {
                            $_.IpAddress
                        }
                        else {
                            "Pool without targets"
                        }
                    }
    
                    $BackendAddressPoolNode = [MermaidNode]::new("backendaddresspool_$($BackendAddressPool.Name)", "Backend Address Pool: $($BackendAddressPool.Name)<br>Targets:<br>$($Backends -join "<br>")")
                    $Diagram.AddEdge($RuleNode.Name, $BackendAddressPoolNode.Name)
                    
                    $BackendHttpSetting = $AppGateway.BackendHttpSettingsCollection | Where-Object Id -eq $Rule.BackendHttpSettings.Id
                    $BackendHttpSettingNode = [MermaidNode]::new("backendhttpsetting_$($BackendHttpSetting.Name)", "Backend HTTP Setting: $($BackendHttpSetting.Name)")
                    $Diagram.AddEdge($RuleNode.Name, $BackendHttpSettingNode.Name)
                }
    
                If ($Rule.RewriteRuleSet) {
                    $RewriteRuleSet = $AppGateway.RewriteRuleSets | Where-Object Id -eq $Rule.RewriteRuleSet.Id
                    $RewriteRuleSetNode = [MermaidNode]::new("rewriteruleset_$($RewriteRuleSet.Name)", "Rewrite Rule Set: $($RewriteRuleSet.Name)")
                    $Diagram.AddEdge($RuleNode.Name, $RewriteRuleSetNode.Name)
                }
            }
        }
    }
    end {

        $MermaidMarkdown = $Diagram.GenerateDiagram()
        #Remove duplicate lines from the diagram
        $MermaidMarkdown = ($MermaidMarkdown -split "`n" | Select-Object -Unique) -join "`n"

        Return [PSCustomObject]@{
            MermaidMarkdown = $MermaidMarkdown
        }
    }
}
