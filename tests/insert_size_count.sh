sed -n "s@  total++;@\{   total++;   upper++;   \}@p" $1
sed -n "s@  amp\_lower\_total++;@\{   amp\_lower\_total++;   lower++;   \}@p" $1

sed -i "s@  total++;@\{   total++;   upper++;   \}@g" $1
sed -i "s@  amp\_lower\_total++;@\{   amp\_lower\_total++;   lower++;   \}@g" $1
