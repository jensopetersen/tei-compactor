xquery version "3.0";

let $doc :=
<doc xml:id="x">
    <a>
        <b x="1">text1<e>text2</e>text3</b>
        </a>
    <a>
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <d y="4">text5</d>
            </c>
    </a>
</doc>

return 
    let $paths :=
        for $node in ($doc//element())
        let $ancestors := $node/ancestor-or-self::*
        let $ancestors := 
          concat(string-join(
            for $ancestor in $ancestors
            return concat(name($ancestor), 
              string-join(
                let $attributes := $ancestor/attribute()
                  for $attribute in $attributes
                  return concat('[@', name($attribute), ']'))
              , '/')
            
        ), if ($node/text())
          then 'text()'
          else 'node()')
        return $ancestors
        
        
    return distinct-values($paths)

#

doc[@xml:id]/a/node()
doc[@xml:id]/a/b[@x]/text()
doc[@xml:id]/a/b[@x]/e/text()
doc[@xml:id]/a/c/node()
doc[@xml:id]/a/c/d[@y][@z]/text()
doc[@xml:id]/a/c/d[@y]/text()