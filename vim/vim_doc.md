[toc]

```
yy 						复制光标所在行yy后按p粘贴；
nyy						复制n行；
3yy						复制3行；
p,P						粘贴；
yw 						复制光标所在的词组，不会复制标点符号；
3yw						复制三个词组；
u  						撤消上一次；  
U  						撤消当前所有；
dd 						删除整行；
d$                      删除光标后面的内容,对光标所在行生效
d^                      删除光标前面的内容,对光标所在行生效
ndd                     删除n行；
x  						删除一个字符；
u  						逐行撤销；
dw 						删除一个词组；      
a						从光标所在字符后一个位置开始录入；
A						从光标所在行的行尾开始录入；
i						从光标所在字符前一个位置开始录入；
I						从光标所在行的行首开始录入；
o						跳至光标所在行的下一行行首开始录入；
O						跳至光标所在行的上一行行首开始录入；
R						从光标所在位置开始替换；
	末行模式主要功能包括：查找、替换、末行保存、退出等；
:w						保存；
:q						退出；    
:s/x/y      			    替换1行；
:wq         			保存退出；
1,5s/x/y     			    替换1,5行；
:wq!        			    强制保存退出；           
1,$sx/y     			    从第一行到最后一行；
:q!						强制退出；
:x						保存；
/word					从前往后找，正向搜索；
?word					从后往前走，反向搜索；
:s/old/new/g      		    将old替换为new，前提是光标一定要移到那一行；
:s/old/new        		将这一行中的第一次出现的old替换为new，只替换第一个；
:1,$s/old/new/g    		第一行到最后一行中的old替换为new；
:1,2,3s/old/new/g  		    第一行第二行第三行中的old改为new；
vim +2 jfedu.txt  		    打开jfedu.txt文件，并将光标定位在第二行；
vim +/string jfedu.txt       打开jfedu.txt文件，并搜索关键词。
```