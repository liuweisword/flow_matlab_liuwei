% 获取图像信息
% 获取最中间的64*64
imag_width = 64;
imag_heigh = 64;

FLOW_FEATURE_THRESHOLD = 30; %原值为30
FLOW_VALUE_THRESHOLD =5000; %原值为5000

imag1=imread('./imag/1.jpg');
%R_imag1 = imag1(:,:,1);
%G_imag1 = imag1(:,:,2);
%B_imag1 = imag1(:,:,3);
gray_imag1=rgb2gray(imag1);
[row_imag1,col_imag1]= size(gray_imag1);
imag1_cut = imcrop(gray_imag1,[(col_imag1-imag_heigh)/2 (row_imag1-imag_width)/2 imag_heigh-1 imag_width-1]);

imag2=imread('./imag/2.jpg');
%R_imag2 = imag2(:,:,1);
%G_imag2 = imag2(:,:,2);
%B_imag2 = imag2(:,:,3);
gray_imag2=rgb2gray(imag2);
[row_imag2,col_imag2]= size(gray_imag2);
imag2_cut = imcrop(gray_imag2,[(col_imag1-imag_heigh)/2 (row_imag1-imag_width)/2 imag_heigh-1 imag_width-1]);

figure(1);
subplot(2,2,1);
imagesc(gray_imag1);
colormap(gray);
title('光流图像第一帧');
rectangle('Position',[(col_imag1-imag_heigh)/2 (row_imag1-imag_width)/2 imag_heigh imag_width],'edgecolor','r');

subplot(2,2,2);
imagesc(gray_imag2);
colormap(gray);
title('光流图像第二帧');
rectangle('Position',[(col_imag2-imag_heigh)/2 (row_imag2-imag_width)/2 imag_heigh imag_width],'edgecolor','r');

subplot(2,2,3);
imagesc(imag1_cut);
colormap(gray);
title('光流图像第一帧裁剪后');
 
subplot(2,2,4);
imagesc(imag2_cut);
colormap(gray);
title('光流图像第二帧裁剪后');




%% 切割成5*5个 8*8的块 第二幅图以[-4,4]的81个方框对比
winmin = -4;
winmax = 4;
win_width = 8;
win_heigh = 8;
Num_blocks = 5;



pixLo = winmax + 1;
pixHi = imag_heigh -(winmax + 1)- win_heigh;

pixStep = floor((pixHi - pixLo)/Num_blocks) +1;
figure(2);
subplot(1,2,1);

imagesc(imag1_cut);
colormap(gray);
title('第一帧边缘检测');
%通过的block计数器
block_pass=[]; % 1~15, pass 对应位置0，不pass置1；
block_temp1=[]; % 为了方便写程序 区别于C语言的串行算法，这里多占用些存储资源 方便计算
block_cnt =1;
for j = pixLo+1 : pixStep :pixHi   %% 特别说明，算法考虑 *base1 = image1 + j * (uint16_t) global_data.param[PARAM_IMAGE_WIDTH] + i;  行其实多算一行
    for i = pixLo : pixStep :pixHi
        
      %取出block标红线
      block_imag1 = imcrop(imag1_cut,[i j win_heigh-1 win_width-1]);
      rectangle('Position',[i j win_heigh win_width],'edgecolor','r');  
      block_temp1(:,:,block_cnt) = block_imag1;
      block_cnt = block_cnt +1;
      
      %取出block中心的4*4 计算diff 标蓝绿线  通过为蓝 不过为绿
      block_4_4 = imcrop(imag1_cut,[i+2 j+2 4 4]);
      block_4_4 = int16(block_4_4);
     
        % block_diff = sum(sum(abs(diff(block_4_4))));%% 这个函数可能呢有点问题  只求了 row 的没有求col
        % 修改为以下
      block_diff = sum(sum(abs(diff(block_4_4)))) + sum(sum(abs(diff(block_4_4'))));
      if block_diff > FLOW_FEATURE_THRESHOLD 
        block_pass=[block_pass 1];
        text(i+2,j+2+1,num2str(block_diff),'color',[0 0.5 1]);
        rectangle('Position',[i+2 j+2 4 4],'edgecolor',[0 0.5 1]);   
      else  
        block_pass=[block_pass 0];
        text(i+2,j+2+1,num2str(block_diff),'color','g');
        rectangle('Position',[i+2 j+2 4 4],'edgecolor','g');   
      end
    end
end
block_temp1 = uint8( block_temp1); %double 变回uint8

%第二张图与第一张图对比  本来在一个打循环中，为了方便画图放入2个循环
block_cnt =1;
figure(2);
subplot(1,2,2);

imagesc(imag2_cut);
colormap(gray);
title('第二帧block匹配');
block_dists =[];
dist_x=[];
dist_y=[];
mean_cnt=0;
acc_sum=[];
subdirs =[];

mindir=0;
for j = pixLo+1 : pixStep :pixHi
    for i = pixLo : pixStep :pixHi
        %图2 对应的num的block
        if block_pass(block_cnt) == 1
         
            block_imag1 = imcrop(imag1_cut,[i j win_heigh-1 win_width-1]);
            rectangle('Position',[i j win_heigh win_width],'edgecolor','r');    %标出初始位置
            
            block_imag1_temp = int16(block_imag1); %防止uint8  6-8=0；
            dist=4294967295;% 0xffffffff 设一个很大的数做初值  找到比较小的数
            
            %81次搜索
            for jj = winmin : winmax
              for ii = winmin :winmax
                block_imag2 = imcrop(imag2_cut,[i+ii j+jj win_heigh-1 win_width-1]);
                block_imag2_temp = int16(block_imag2);
                dist_temp = sum(sum(abs(block_imag2_temp - block_imag1_temp))); 
                
                %如果距离更小则保存
                if(dist_temp<dist)
                    dist_x_temp = ii;
                    dist_y_temp = jj;
                    dist = dist_temp;
                end
                
              end
            end
            %判断是否超出阈值 差异过大
            if dist < FLOW_VALUE_THRESHOLD
              
                
                %加入0.5像素修正 对匹配的这两个8*8 求每个像素的SAD
                %对imag)cut2 8*8的每个点求
                %        * the 8 s values are from following positions for each pixel (X):
                % 		 *  + - + - + - +
                % 		 *  +   5   7   +
                % 		 *  + - + 6 + - +
                % 		 *  +   4 X 0 m0+
                % 		 *  + - + 2 + - +
                % 		 *  +   3   1   +
                % 		 *  + - + - + - +
                %取出对应的8个矩阵 用于计算
                acc = zeros(1,8);  %八个方向
                block_imag2_temp= uint16(imcrop(imag2_cut,[i+dist_x_temp  j+dist_y_temp    win_heigh-1 win_width-1]));
                block_imag1_temp= uint16(imcrop(imag1_cut,[i  j  win_heigh-1 win_width-1]));
                m0 = uint16(imcrop(imag2_cut,[i+dist_x_temp+1  j+dist_y_temp    win_heigh-1 win_width-1]));
                m1 = uint16(imcrop(imag2_cut,[i+dist_x_temp+1  j+dist_y_temp+1  win_heigh-1 win_width-1]));
                m2 = uint16(imcrop(imag2_cut,[i+dist_x_temp    j+dist_y_temp+1  win_heigh-1 win_width-1]));
                m3 = uint16(imcrop(imag2_cut,[i+dist_x_temp-1  j+dist_y_temp+1  win_heigh-1 win_width-1]));
                m4 = uint16(imcrop(imag2_cut,[i+dist_x_temp-1  j+dist_y_temp    win_heigh-1 win_width-1]));
                m5 = uint16(imcrop(imag2_cut,[i+dist_x_temp-1  j+dist_y_temp-1  win_heigh-1 win_width-1]));
                m6 = uint16(imcrop(imag2_cut,[i+dist_x_temp    j+dist_y_temp-1  win_heigh-1 win_width-1]));
                m7 = uint16(imcrop(imag2_cut,[i+dist_x_temp+1  j+dist_y_temp-1  win_heigh-1 win_width-1]));
                
                s0 = (block_imag2_temp + m0 )/2;
                s1 = (m2 + m0 )/2;
                s2 = (block_imag2_temp + m2 )/2;
                s3 = (m2 + m3 )/2;
                s4 = (block_imag2_temp + m4 )/2;
                s5 = (m5 + m6 )/2;
                s6 = (block_imag2_temp + m6 )/2;
                s7 = (m6 + m7 )/2;
                t1 = (s0 + s1)/2;
                t3 = (s3 + s4)/2;
                t5 = (s4 + s5)/2;
                t7 = (s7 + s0)/2;
                
                acc(1,1) = sum(sum(abs(block_imag1_temp - s0)));
                acc(1,2) = sum(sum(abs(block_imag1_temp - t1)));
                acc(1,3) = sum(sum(abs(block_imag1_temp - s2)));
                acc(1,4) = sum(sum(abs(block_imag1_temp - t3)));
                acc(1,5) = sum(sum(abs(block_imag1_temp - s4)));
                acc(1,6) = sum(sum(abs(block_imag1_temp - t5)));
                acc(1,7) = sum(sum(abs(block_imag1_temp - s6)));
                acc(1,8) = sum(sum(abs(block_imag1_temp - t7)));
                
                [mindist mindir] = min(acc);
                if  (mindir == 0 || mindir == 1 || mindir == 7) dist_x_temp = dist_x_temp + 0.5;end
                if  (mindir == 3 || mindir == 4 || mindir == 5) dist_x_temp = dist_x_temp - 0.5;end
                if  (mindir == 5 || mindir == 6 || mindir == 7) dist_y_temp = dist_y_temp - 0.5;end
                if  (mindir == 2 || mindir == 2 || mindir == 3) dist_y_temp = dist_y_temp + 0.5;end
                dist_x = [dist_x dist_x_temp];
                dist_y = [dist_y dist_y_temp];
                mean_cnt = mean_cnt+1;
                rectangle('Position',[i+dist_x_temp j+dist_y_temp win_heigh win_width],'edgecolor',[1 1 0]);    %标出匹配位置
                text(i+dist_x_temp,j+dist_y_temp+1,num2str(dist),'color',[1 1 0]);
                text(i,j+1,['(',num2str(dist_x_temp),',',num2str(dist_y_temp),')'],'color','r');
                
            else
                rectangle('Position',[i+dist_x_temp j+dist_y_temp win_heigh win_width],'edgecolor','g');    %标出匹配但超越阈值位置
                text(i+dist_x_temp,j+dist_y_temp+1,num2str(dist),'color','g');
                text(i,j+1,['(',num2str(dist_x_temp),',',num2str(dist_y_temp),')'],'color','r');
            end
     
        end
       block_cnt = block_cnt +1;  
    end
end


flow_x = floor(sum(dist_x)/mean_cnt);
flow_y = floor(sum(dist_y)/mean_cnt);

if  mean_cnt > 10
    
    text(1,1,['(',num2str(flow_x),',',num2str(flow_y),')'],'color','r');
else
    text(1,1,['(',num2str(flow_x),',',num2str(flow_y),')'],'color','g');


end

flow_x = sum(dist_x)/mean_cnt;
flow_y = sum(dist_y)/mean_cnt;
if  mean_cnt > 10
    
    text(imag_width-10,1,['(',num2str(flow_x),',',num2str(flow_y),')'],'color','r');
else
    text(imag_width-10,1,['(',num2str(flow_x),',',num2str(flow_y),')'],'color','g');


end









