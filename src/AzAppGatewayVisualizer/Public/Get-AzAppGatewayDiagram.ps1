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
        $MermaidMarkdown = "graph $($GraphDirection)`n"
        If ($Hostnames -eq "All") {
            $Hostnames = $AppGateway.HttpListeners.Hostname | Select-Object -Unique
        }
    }
    
    process {
        foreach ($Hostname in $Hostnames) {
            $Listeners = $AppGateway.HttpListeners | Where-Object { $_.Hostname -eq $Hostname }
            foreach ($Listener in $Listeners) {
                if ($Listener.FirewallPolicy.Id) {
                    $WafPolicy = Get-AzResource -Id $Listener.FirewallPolicy.Id
                    $MermaidMarkdown += "wafpolicy_$($WafPolicy.Name)[WAF policy: $($WafPolicy.Name)] --> listener_$($Listener.Name)`n"
                }
                $FrontendIpConfiguration = $AppGateway.FrontendIPConfigurations | Where-Object Id -eq $Listener.FrontendIpConfiguration.Id
                $MermaidMarkdown += "frontendipconfiguration$($FrontendIpConfiguration.Name)[Frontend IP: $($FrontendIpConfiguration.Name)] ---> listener_$($Listener.Name)`n"
                
                $MermaidMarkdown += "listener_$($Listener.Name)[Listener: $($Listener.Name)<br>Hostname: $($Hostname)<br>Port: $($Listener.FrontendPort.Id.Split('_')[-1])<br>Protocol: $($Listener.Protocol.ToUpper())]`n"
                
                if ($Listener.Protocol -eq 'Https') {
                    $SslCert = $AppGateway.SslCertificates | Where-Object Id -eq $Listener.SslCertificate.Id
                    $MermaidMarkdown += "sslcert_$($SslCert.Name)[SSL Cert: $($SslCert.Name)] --> listener_$($Listener.Name)`n"
                    If ($SslCert.KeyVaultSecretId) {
                        $KeyVaultCertificateId = $SslCert.KeyVaultSecretId.Replace('secrets', 'certificates')
                        $KeyVaultCertificateName = $KeyVaultCertificateId.Split('/')[4]
                        $MermaidMarkdown += "sslcert_$($SslCert.Name) --> keyvaultcert_$($KeyVaultCertificateName)[Key Vault Certificate: $($KeyVaultCertificateId.TrimEnd('/'))]`n"
                    }
                }

                $Rule = $AppGateway.RequestRoutingRules | Where-Object { $_.HttpListener.Id -eq $Listener.Id }
                $MermaidMarkdown += "listener_$($Listener.Name) --> rule_$($Rule.Name)[Request Routing Rule: $($Rule.Name)]`n"
                if ($Rule.UrlPathMap.Id) {
                    $UrlPathMap = $AppGateway.UrlPathMaps | Where-Object Id -eq $Rule.UrlPathMap.Id
                    Foreach ($PathRule in $UrlPathMap.PathRules) {
                        $MermaidMarkdown += "rule_$($Rule.Name) -- URL Paths: $($UrlPathMap.PathRules.Paths -join '<br>') ---> urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name)[Path Rule: $($PathRule.Name)]`n"
                        
                        If ($PathRule.BackendAddressPool) {
                            $BackendAddressPool = $AppGateway.BackendAddressPools | Where-Object Id -eq $PathRule.BackendAddressPool.Id
                            $MermaidMarkdown += "urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name) --> backendaddresspool_$($BackendAddressPool.Name)[Backend Address Pool: $($BackendAddressPool.Name)]`n"
                            
                            $BackendHttpSetting = $AppGateway.BackendHttpSettingsCollection | Where-Object Id -eq $PathRule.BackendHttpSettings.Id
                            $MermaidMarkdown += "urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name) --> backendhttpsetting_$($BackendHttpSetting.Name)[Backend HTTP Setting: $($BackendHttpSetting.Name)]`n"
                        }
                        
                        If ($PathRule.RewriteRuleSet) {
                            $RewriteRuleSet = $AppGateway.RewriteRuleSets | Where-Object Id -eq $PathRule.RewriteRuleSet.Id
                            $MermaidMarkdown += "urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name) --> rewriteruleset_$($RewriteRuleSet.Name)[Rewrite Rule Set: $($RewriteRuleSet.Name)]`n"
                            
                        }

                        $RedirectConfiguration = $AppGateway.RedirectConfigurations | Where-Object Id -eq $($AppGateway.Id + "/redirectConfigurations/" + $Rule.Name + "_" + $PathRule.Name)
                        If ($RedirectConfiguration.TargetUrl) {
                            $MermaidMarkdown += "urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name) -- Redirects to --> redirectconfiguration_$($RedirectConfiguration.Name)[External URL: $($RedirectConfiguration.TargetUrl)]`n"
                        }
                        elseif ($RedirectConfiguration.TargetListener) {
                            $MermaidMarkdown += "urlpathmap_$($UrlPathMap.Name)_$($PathRule.Name) -- Redirects to --> listener_$($RedirectConfiguration.TargetListener.Id.Split('/')[-1])`n"  
                        }
                    }   
                }
            }

            $RedirectConfiguration = $AppGateway.RedirectConfigurations | Where-Object Id -eq $($AppGateway.Id + "/redirectConfigurations/" + $Rule.Name)
            If ($RedirectConfiguration) {
                If ($RedirectConfiguration.TargetUrl) {
                    $MermaidMarkdown += "rule_$($Rule.Name) -- Redirects to --> redirectconfiguration_$($RedirectConfiguration.Name)[External URL: $($RedirectConfiguration.TargetUrl)]`n"
                }
                Else {
                    $MermaidMarkdown += "rule_$($Rule.Name) -- Redirects to --> listener_$($RedirectConfiguration.TargetListener.Id.Split('/')[-1])`n"
                }  
            }

            If ($Rule.BackendAddressPool) {
                $MermaidMarkdown += "rule_$($Rule.Name) --> rule_$($Rule.Name)_split[ ]`nstyle rule_$($Rule.Name)_split fill:#fff,stroke:#fff,stroke-width:0px;`n"

                $BackendAddressPool = $AppGateway.BackendAddressPools | Where-Object Id -eq $Rule.BackendAddressPool.Id
                $MermaidMarkdown += "rule_$($Rule.Name)_split --> backendaddresspool_$($BackendAddressPool.Name)[Backend Address Pool: $($BackendAddressPool.Name)]`n"

                $BackendHttpSetting = $AppGateway.BackendHttpSettingsCollection | Where-Object Id -eq $Rule.BackendHttpSettings.Id
                $MermaidMarkdown += "rule_$($Rule.Name)_split --> backendhttpsetting_$($BackendHttpSetting.Name)[Backend HTTP Setting: $($BackendHttpSetting.Name)]`n"
            }

            If ($Rule.RewriteRuleSet) {
                $RewriteRuleSet = $AppGateway.RewriteRuleSets | Where-Object Id -eq $Rule.RewriteRuleSet.Id
                $MermaidMarkdown += "rule_$($Rule.Name)_split --> rewriteruleset_$($RewriteRuleSet.Name)[Rewrite Rule Set: $($RewriteRuleSet.Name)]`n"
            }
        }
    }
    end {
        Return [PSCustomObject]@{
            MermaidMarkdown = $MermaidMarkdown
        }
    }
}
