while read line; do echo "$line :"; jar vtf $line | grep Path.class;done < test.txt
