xquery version "3.0";

(:let $doc := doc('/db/test/test-doc.xml'):)
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
                        if (normalize-space(string($ancestor/string())) ne ' ' and $ancestor/element())
                        then '[text()][element()]'
                        else 
                            if (normalize-space($ancestor/text()) ne ' ')
                            then '[text()]'
                            else 'XXX'
                )
                    , '/'
                    )
                )
              , 
              if (normalize-space($node/string()) ne ' ' and $node/element())
              then '(text(), element())'
              else 
                  if (normalize-space($node/text()) ne ' ')
                  then 'text()'
                  else
                      if ($node/element())
                      then 'element()'
                      else 
                          if ($node/attribute())
                          then 'attribute()'
                          else 'YYY'
            )
        return $ancestors
    return distinct-values($paths)
