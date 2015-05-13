% ��ȡͼ����Ϣ
% ��ȡ���м��64*64
imag_width = 64;
imag_heigh = 64;

FLOW_FEATURE_THRESHOLD = 30; %ԭֵΪ30
FLOW_VALUE_THRESHOLD =5000; %ԭֵΪ5000

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
title('����ͼ���һ֡');
rectangle('Position',[(col_imag1-imag_heigh)/2 (row_imag1-imag_width)/2 imag_heigh imag_width],'edgecolor','r');

subplot(2,2,2);
imagesc(gray_imag2);
colormap(gray);
title('����ͼ��ڶ�֡');
rectangle('Position',[(col_imag2-imag_heigh)/2 (row_imag2-imag_width)/2 imag_heigh imag_width],'edgecolor','r');

subplot(2,2,3);
imagesc(imag1_cut);
colormap(gray);
title('����ͼ���һ֡�ü���');
 
subplot(2,2,4);
imagesc(imag2_cut);
colormap(gray);
title('����ͼ��ڶ�֡�ü���');




%% �и��5*5�� 8*8�Ŀ� �ڶ���ͼ��[-4,4]��81������Ա�
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
title('��һ֡��Ե���');
%ͨ����block������
block_pass=[]; % 1~15, pass ��Ӧλ��0����pass��1��
block_temp1=[]; % Ϊ�˷���д���� ������C���ԵĴ����㷨�������ռ��Щ�洢��Դ �������
block_cnt =1;
for j = pixLo+1 : pixStep :pixHi   %% �ر�˵�����㷨���� *base1 = image1 + j * (uint16_t) global_data.param[PARAM_IMAGE_WIDTH] + i;  ����ʵ����һ��
    for i = pixLo : pixStep :pixHi
        
      %ȡ��block�����
      block_imag1 = imcrop(imag1_cut,[i j win_heigh-1 win_width-1]);
      rectangle('Position',[i j win_heigh win_width],'edgecolor','r');  
      block_temp1(:,:,block_cnt) = block_imag1;
      block_cnt = block_cnt +1;
      
      %ȡ��block���ĵ�4*4 ����diff ��������  ͨ��Ϊ�� ����Ϊ��
      block_4_4 = imcrop(imag1_cut,[i+2 j+2 4 4]);
      block_4_4 = int16(block_4_4);
     
        % block_diff = sum(sum(abs(diff(block_4_4))));%% ��������������е�����  ֻ���� row ��û����col
        % �޸�Ϊ����
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
block_temp1 = uint8( block_temp1); %double ���uint8

%�ڶ���ͼ���һ��ͼ�Ա�  ������һ����ѭ���У�Ϊ�˷��㻭ͼ����2��ѭ��
block_cnt =1;
figure(2);
subplot(1,2,2);

imagesc(imag2_cut);
colormap(gray);
title('�ڶ�֡blockƥ��');
block_dists =[];
dist_x=[];
dist_y=[];
mean_cnt=0;
acc_sum=[];
subdirs =[];

mindir=0;
for j = pixLo+1 : pixStep :pixHi
    for i = pixLo : pixStep :pixHi
        %ͼ2 ��Ӧ��num��block
        if block_pass(block_cnt) == 1
         
            block_imag1 = imcrop(imag1_cut,[i j win_heigh-1 win_width-1]);
            rectangle('Position',[i j win_heigh win_width],'edgecolor','r');    %�����ʼλ��
            
            block_imag1_temp = int16(block_imag1); %��ֹuint8  6-8=0��
            dist=4294967295;% 0xffffffff ��һ���ܴ��������ֵ  �ҵ��Ƚ�С����
            
            %81������
            for jj = winmin : winmax
              for ii = winmin :winmax
                block_imag2 = imcrop(imag2_cut,[i+ii j+jj win_heigh-1 win_width-1]);
                block_imag2_temp = int16(block_imag2);
                dist_temp = sum(sum(abs(block_imag2_temp - block_imag1_temp))); 
                
                %��������С�򱣴�
                if(dist_temp<dist)
                    dist_x_temp = ii;
                    dist_y_temp = jj;
                    dist = dist_temp;
                end
                
              end
            end
            %�ж��Ƿ񳬳���ֵ �������
            if dist < FLOW_VALUE_THRESHOLD
              
                
                %����0.5�������� ��ƥ���������8*8 ��ÿ�����ص�SAD
                %��imag)cut2 8*8��ÿ������
                %        * the 8 s values are from following positions for each pixel (X):
                % 		 *  + - + - + - +
                % 		 *  +   5   7   +
                % 		 *  + - + 6 + - +
                % 		 *  +   4 X 0 m0+
                % 		 *  + - + 2 + - +
                % 		 *  +   3   1   +
                % 		 *  + - + - + - +
                %ȡ����Ӧ��8������ ���ڼ���
                acc = zeros(1,8);  %�˸�����
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
                rectangle('Position',[i+dist_x_temp j+dist_y_temp win_heigh win_width],'edgecolor',[1 1 0]);    %���ƥ��λ��
                text(i+dist_x_temp,j+dist_y_temp+1,num2str(dist),'color',[1 1 0]);
                text(i,j+1,['(',num2str(dist_x_temp),',',num2str(dist_y_temp),')'],'color','r');
                
            else
                rectangle('Position',[i+dist_x_temp j+dist_y_temp win_heigh win_width],'edgecolor','g');    %���ƥ�䵫��Խ��ֵλ��
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









