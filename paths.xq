xquery version "3.0";

let $doc := doc('/db/test/test-doc.xml')
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


let $doc := doc('/db/apps/shakespeare/data/ham.xml')
return 
    let $paths :=
        for $node in ($doc//element(), $doc//attribute(), $doc//text())
        let $ancestors := $node/ancestor-or-self::*
        let $ancestors := 
            concat
            (
                string-join
                (
                for $ancestor in $ancestors
                return 
                    concat
                    (
                        name($ancestor)
                        ,
                        string-join
                        (
                            let $attributes := $ancestor/attribute()
                            for $attribute in $attributes
                            return concat('[@', name($attribute), ']'
                        )
                        ,
                        if (normalize-space(string-join($ancestor/text())) ne '' and $ancestor/element())
                        then '[text()][element()]'
                        else 
                            if (normalize-space(string-join($ancestor/text())) ne '')
                            then '[text()]'
                            else 
                                if ($ancestor/element())
                                then '[element()]'
                                else 'XXX'
                )
                    , '/'
                    )
                )
              , 
              if (normalize-space(string-join($node/text())) ne '' and $node/element())
              then '(text(), element())'
              else 
                  if (normalize-space(string-join($node/text())) ne '')
                  then 'text()'
                  else
                      if ($node/element())
                      then 'element()'
                      else 
                          if ($node/attribute())
                          then 'attribute()'
                          else '' (:attribute value:)
            )
        return $ancestors
    let $paths := distinct-values($paths)
    return
        <paths>
            {
            for $path in $paths
            return
                <path>{$path}</path>
            }
        </paths>
