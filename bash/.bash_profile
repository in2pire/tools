
for file in ~/.bash/*
do
  source "$file"
done

PS1="🍺  \u@\h:\033[31m\W\033[0m\033[32m\$(prompt_universal)\033[0m $ "
