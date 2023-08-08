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
    [string]$Label
    [string]$LeftNode
    [string]$RightNode
    
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
        [string]$Label
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
        $this.Label = $Label
    }
}

Class MermaidDiagram {
    [string]$GraphDirection=$TB
    [System.Collections.Generic.List[MermaidNode]]$Nodes = [System.Collections.Generic.List[MermaidNode]]::new()
    [System.Collections.Generic.List[MermaidLink]]$Links = [System.Collections.Generic.List[MermaidLink]]::new()

    MermaidDiagram(){}

    MermaidDiagram(
        [string]$GraphDirection
    ) {
        $this.GraphDirection =$GraphDirection
    }

    #Add by name and label
    [void]AddNode(
        [string]$Name, 
        [string]$Label
    ) {
        $Node = [MermaidNode]::new($Name, $Label)
        $this.Nodes.Add($Node)
    }

    #Add node by node object
    [void]AddNode(
        [MermaidNode]$Node
    ) {
        $this.Nodes.Add($Node)
    }

    [void]AddLink(
        [string]$LeftNode,
        [string]$RightNode
    ) {
        $Link = [MermaidLink]::new($LeftNode, $RightNode)
        $this.Links.Add($Link)
    }

    [void]AddLink(
        [string]$LeftNode,
        [string]$RightNode,
        [string]$Label
    ) {
        $Link = [MermaidLink]::new($LeftNode, $RightNode, $Label)
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

            $MermaidMarkdown.Append(" --> ")

            $MermaidMarkdown.AppendLine($Link.RightNode)
        }

        $MermaidMarkdown = ($MermaidMarkdown -split "`n" | Select-Object -Unique) -join "`n"

        return $MermaidMarkdown
    }
}