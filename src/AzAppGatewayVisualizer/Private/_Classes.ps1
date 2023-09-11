class MermaidNode {
    [string]$Name
    [string]$Label

    MermaidNode(
        [string]$Name,
        [string]$Label
    ) {
        $this.Name = $Name
        $this.Label = $Label
    }
}

Class MermaidLink {
    [string]$LeftNode
    [string]$RightNode
    [string]$Label = $null
    [int]$MinimumLength = 1
    
    MermaidLink (        
        [string]$LeftNode,
        [string]$RightNode
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
    }

    MermaidLink (        
        [string]$LeftNode,
        [string]$RightNode,
        [int]$MinimumLength
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
        $this.MinimumLength = $MinimumLength
    }

    MermaidLink (        
        [string]$LeftNode,
        [string]$RightNode,
        [string]$Label
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
        $this.Label = $Label
    }

    MermaidLink (        
        [string]$LeftNode,
        [string]$RightNode,
        [string]$Label,
        [int]$MinimumLength
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
        $this.Label = $Label
        $this.MinimumLength = $MinimumLength
    }
}

Class MermaidDiagram {
    [string]$GraphDirection = $TB
    [System.Collections.Generic.List[MermaidNode]]$Nodes = [System.Collections.Generic.List[MermaidNode]]::new()
    [System.Collections.Generic.List[MermaidLink]]$Links = [System.Collections.Generic.List[MermaidLink]]::new()

    MermaidDiagram() {}

    MermaidDiagram(
        [string]$GraphDirection
    ) {
        $this.GraphDirection = $GraphDirection
    }

    [void]AddNode(
        [MermaidNode]$Node
    ) {
        $this.Nodes.Add($Node)
    }

    [void]AddLink(
        [MermaidLink]$Link
    ) {
        $this.Links.Add($Link)
    }

    [string]GenerateDiagram() {

        $MermaidMarkdown = [System.Text.StringBuilder]::new()
        $MermaidMarkdown.AppendLine("graph $($this.GraphDirection)")

        foreach ($Node in $this.Nodes) {
            $MermaidMarkdown.Append('  ')
            $MermaidMarkdown.Append($Node.Name)
            $MermaidMarkdown.AppendLine("[""$($Node.Label)""]")
        }

        foreach ($Link in $this.Links) {
            $MermaidMarkdown.Append('  ')
            $MermaidMarkdown.Append($Link.LeftNode)

            If ($Link.Label) {
                $MermaidMarkdown.Append(" -- $($Link.Label)")
            }

            $MermaidMarkdown.Append(" ")
            For ($i=0; $i -le $Link.MinimumLength; $i++){
                $MermaidMarkdown.Append("-")
            }
            $MermaidMarkdown.Append("> ")

            $MermaidMarkdown.AppendLine($Link.RightNode)
        }

        $MermaidMarkdown = ($MermaidMarkdown -split "`n" | Select-Object -Unique) -join "`n"

        return $MermaidMarkdown
    }
}

$diagram=[mermaidDiagram]::new()    
$node1=[mermaidNode]::new("node1","node1")    
$diagram.AddNode($node1)

$diagram.AddLink("node1","node1",2)
$diagram.AddLink("node1","node1",3)
$diagram.AddLink("node1","node1",4)