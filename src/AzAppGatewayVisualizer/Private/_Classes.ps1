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

Class MermaidEdge {
    [string]$Label
    [string]$LeftNode
    [string]$RightNode
    
    MermaidEdge (        
        [string]$LeftNode,
        [string]$RightNode
    ) {
        $this.LeftNode = $LeftNode
        $this.RightNode = $RightNode
    }

    MermaidEdge (        
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
    [System.Collections.Generic.List[MermaidEdge]]$Edges = [System.Collections.Generic.List[MermaidEdge]]::new()

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

    [void]AddEdge(
        [string]$LeftNode,
        [string]$RightNode
    ) {
        $Edge = [MermaidEdge]::new($LeftNode, $RightNode)
        $this.Edges.Add($Edge)
    }

    [void]AddEdge(
        [string]$LeftNode,
        [string]$RightNode,
        [string]$Label
    ) {
        $Edge = [MermaidEdge]::new($LeftNode, $RightNode, $Label)
        $this.Edges.Add($Edge)
    }

    [string]GenerateDiagram() {

        $MermaidMarkdown = [System.Text.StringBuilder]::new()
        $MermaidMarkdown.AppendLine("graph $($this.GraphDirection)")

        foreach ($Node in $this.Nodes) {
            $MermaidMarkdown.Append('  ')
            $MermaidMarkdown.Append($Node.Name)
            $MermaidMarkdown.AppendLine("[""$($Node.Label)""]")
        }

        foreach ($Edge in $this.Edges) {
            $MermaidMarkdown.Append('  ')
            $MermaidMarkdown.Append($Edge.LeftNode)

            If ($Edge.Label) {
                $MermaidMarkdown.Append(" -- $($Edge.Label)")
            }

            $MermaidMarkdown.Append(" --> ")

            $MermaidMarkdown.AppendLine($Edge.RightNode)
        }

        $MermaidMarkdown = ($MermaidMarkdown -split "`n" | Select-Object -Unique) -join "`n"

        return $MermaidMarkdown
    }
}