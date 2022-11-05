.data 0x0000				      		
	buf: .word 0x0000
.text 0x0000
#寄存器初始化				
start:
	lui   $1,0xFFFF	                    
        ori   $28,$1,0xF000         #设置$28=0xFFFFF000
        lui   $12,0x0000               #$12=0

        ori $27,$12,0x8000         #设置$27=0x00008000
	#16
	ori $26,$12,0x0010          #$26 = 16
	ori $19,$12,0x0001         #$19=1
	ori $18,$12,0x0000         #$18=0

#检测高16位的是什么而去label
main:
	lui $8,0xffff                        
        ori $8,$8,0xffff
        sw $8,0xC62($28)       #确认处于main状态 用于debug

	lw $2,0xC72($28)            #获取左边八个拨码开关的值，即$2=样例编号
	ori $13,$12,0x0000          #$13=24'b0,00000000
	beq $2,$13,L1                  #进入场景0
	ori $13,$12,0x0020          #$13=24'b0,00100000       
	beq $2,$13,L2_1              
	ori $13,$12,0x0040          #$13=24'b0,01000000
	beq $2,$13,L3                
	ori $13,$12,0x0060          #$13=24'b0,01100000
	beq $2,$13,L4
	ori $13,$12,0x0080          #$13=24'b0,10000000
	beq $2,$13,L5
	ori $13,$12,0x00a0          #$13=24'b0,10100000
	beq $2,$13,L6
	ori $13,$12,0x00c0          #$13=24'b0,11000000
	beq $2,$13,L7
	ori $13,$12,0x00e0          #$13=24'b0,11100000
	beq $2,$13,L8
	j main

L1:
       #case : 000
	lw $2,0xC72($28)
	#(1)load the data from right 16bit
	#20:origin
	lw   $20,0xC70($28)
        sw   $20,0xC60($28)            
	beq $2,$12,L1                #不停地读数字，直到确认键拨起（即前八个拨码开关不全是0）
	

	#21:find meaningful number
        add   $21,$12,$20          #copy
	#24:get reverse
	add   $24,$12,$20          #copy
	ori $22,$12,0x0000          #22是counter，计算输入数前面有多少0

loop:
	and $23,$21,$27                #$27=0x00008000
	beq $23,$27,endloop         #第16bit就是1跳出循环（为了特判原始数据16bit就是1的情况）
	sll $21,$21,1                      #不是1就左移
	add $22,$22,$19               #计数器加1
	#27:0x80000000,see if the highest bit is 1
	#23:highest bit, if not equal to 0x8000000, keep loop
	bne $23,$27,loop              #第16bit不是1继续循环
endloop:
	#22:meaningful digit
	sub $22,$26,$22               #找到有效位数
	ori $25,$12,0x0000           #$25存放reverse的结果

	looper:
	#23:lowest digit, 19:0x00000001
	and $23,$24,$19                #取出最后1bit
	#22:now being a counter, sub 1
	srl $24,$24,1                       #右移1bit
	sub $22,$22,$19                  #计数器+1
	#25:reverse
	sll $25,$25,1                        
	add $25,$25,$23                 #将取出的bit放到reverse数的最低bit
	
	#if counter 22 != 18 : 0x00000000,keep looper
	bne $22,$18,looper              #循环至计数器=有效位数

	#if orgin20 != reverse 25,nothing shows
	bne $25,$20,nothing             #判断是否回文数
	#show 0x00000001,at high bit

show:
	sw $19,0xC62($28)               #显示灯亮
	lw $2,0xC72($28)           #判断拨码开关状态        
	beq $2,$26,show             #左数第四个键为确认键，拨起跳出场景0回到main
	j main                                   

nothing: 	
	lw $2,0xC72($28)
	beq $2,$26,nothing               
	j main


	
L2_1:
        lui   $1,0x0000	                  
        ori   $11,$1,0x0030    #$11=0x00000030
	lw $3,0xC70($28)       #输入A到$3
	sw $3,0xC60($28)      #显示A到
	lw $2,0xC72($28)      
	bne $2,$11,L2_1         #左数第四个键为确认键，往下执行

L2_2:
        lui   $1,0x0000	
        ori   $11,$1,0x0030
	lw $4,0xC70($28)
	sw $4,0xC60($28)      #输入B，显示B  $4
	lw $2,0xC72($28)
	beq $2,$11,L2_2         
	j main                          #拨起左数第五个键回main

L3: #a&b
	and $5,$3,$4
L3_reback:
        lui   $1,0x0000	                  
        ori   $11,$1,0x0040
	sw $5,0xC60($28)          #显示结果
	lw $2,0xC72($28)           
	beq $2,$11,L3_reback     #拨起左数第五个键回main
	j main

L4: #a or b
	or $5,$3,$4
L4_reback:
        lui   $1,0x0000	
        ori   $11,$1,0x0060
	sw $5,0xC60($28)
	lw $2,0xC72($28)
	beq $2,$11,L4_reback
	j main

L5: #a ^ b
	xor $5,$3,$4
L5_reback:
        lui   $1,0x0000	
        ori   $11,$1,0x0080
	sw $5,0xC60($28)        #显示结果
	lw $2,0xC72($28)
	beq $2,$11,L5_reback    #拨起左数第五个键回main
	j main

L6:   
	lui $10,0x0000               #计数器
	add $6,$12,$3               #$6 = 0+A = A，最后为移位结果
L6_loop:
	sll $6,$6,1
        addi $10,$10,1
	bne $10,$4,L6_loop       #$4=B

store:
        lui   $1,0x0000	
        ori   $11,$1,0x00a0
	sw $6,0xC60($28)         #显示结果 
	lw $2,0xC72($28)
	beq $2,$11, store
	j main                             #拨起左数第五个键回main

L7:
	lui $10,0x0000              #计数器
	add $6,$12,$3              #$6 = 0+A = A，最后为移位结果
L7_loop:
	
	srl $6,$6,1
        addi $10,$10,1
	bne $10,$4,L7_loop
	#sll $6,$6,18                #为验证算数右移和逻辑右移设置的样例
	#srl $6,$6,24

store_7:
         lui   $1,0x0000	
        ori   $11,$1,0x00c0
	sw $6,0xC60($28)
	lw $2,0xC72($28)
	beq $2,$11, store_7
	j main

L8:
	lui $10,0x0000
	add $6,$12,$3
L8_loop:
	
	sra $6,$6,1
        addi $10,$10,1
	bne $10,$4,L8_loop
	#sll $6,$6,18		 #为验证算数右移和逻辑右移设置的样例
	#sra $6,$6,24

store_8:
        lui   $1,0x0000	
        ori   $11,$1,0x00e0
	sw $6,0xC60($28)        #显示结果
	lw $2,0xC72($28)
	beq $2,$11, store_8      #拨起左数第五个键回main
	j main
	
	
	
