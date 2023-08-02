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

    [void]AddNode(
        [string]$Name, 
        [string]$Label
    ) {
        $Node = [MermaidNode]::new($Name, $Label)
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
        return $MermaidMarkdown
    }
}


$Diagram = [MermaidDiagram]::new()

$Diagram.AddNode("rule_httpRule-1", "HTTP Rule 1")
$Diagram.AddNode("rule_httpRule-2", "HTTP Rule 2")
$Diagram.AddEdge("rule_httpRule-1", "rule_httpRule-2", "Redirects to")
$Diagram.AddEdge("rule_httpRule-1", "rule_httpRule-2")
$Diagram.GenerateDiagram()