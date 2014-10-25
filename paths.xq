xquery version "3.0";

let $doc := 
<doc xml:id="x">
    <a>
        <b x="1">text1<e>text2</e>text3</b>
        </a>
    <a u="5">
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <e y="4">text5<p n="6"/>text6</e>
            </c>
    </a>
</doc>

let $doc := doc('/db/test/test-doc.xml')
let $c := $doc//c

return 
    <counts>
        <nodes>
            <node-count>{count($c/node())}</node-count>
            <node-paths>
                {for $node in $c/node() 
                return
                    <node-path>{$node/string-join(ancestor-or-self::*/name(.), '/')}</node-path> 
                }
            </node-paths>
        </nodes>
        <text>
            <text-count>{count($c/text())}</text-count>
            <text-paths> 
            {for $node in $c/text() 
            return
                <text-path>{$node/string-join(ancestor-or-self::*/name(.), '/')}</text-path> }
            </text-paths>
        </text>
        <elements>
            <element-count>{count($c/element())}</element-count>
            <element-paths> 
                {for $node in $c/element() 
                return
                    <element-path>{$node/string-join(ancestor-or-self::*/name(.), '/')}</element-path> }
            </element-paths>
        </elements>
    </counts>
