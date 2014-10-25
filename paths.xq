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
        for $node in ($doc//element(), $doc//attribute(), $doc//text())
        (:I would have thought that $doc//node() would do the job …:)
        let $path := 
            if ($node instance of attribute())
            then concat($node/string-join(ancestor-or-self::*/name(.), '/'), '/@', name($node))
            else
                if ($node instance of text())
                then concat($node/string-join(ancestor-or-self::*/name(.), '/'), '/text()')
                else 
                    if ($node/attribute() and $node/text())
                    then concat($node/string-join(ancestor-or-self::*/name(.), '/'), 
                      string-join(
                        for $attribute in $node/attribute()
                        let $attr-name := name($attribute)
                        order by $attr-name
                        return concat('[@', $attr-name, ']')
                        , '')
                      , '[text()]')
                    else 
                      if ($node/attribute())
                      then concat($node/string-join(ancestor-or-self::*/name(.), '/'), 
                        string-join(
                          for $attribute in $node/attribute()
                          let $attr-name := name($attribute)
                          order by $attr-name
                          return concat('[@', $attr-name, ']')
                          , ''))
                      else
                        if ($node/text())
                        then concat($node/string-join(ancestor-or-self::*/name(.), '/'), '[text()]')
                    else $node/string-join(ancestor-or-self::*/name(.), '/')
        order by $path ascending
        return $path
    return distinct-values($paths)
