% Script for total analysis of the optical properties of the cell spread function
% INPUT: 12bit RAW file of the segmented z-stack of the cell, the
% particular PDG matrices, and matrices with modes of the background and
% shape of the envelope
% OUTPUT: .png format of the 3D images of the large homogenous organelles (binary mask from PDG = 0),
% separately for each colour channel and pixels which are darker and brighter than the mode of the background
% and their OSFs
% Application:
% 1. Change parameters in lines 18-21.
% 2. Launch the script.

clear all; close all; clc;
opengl('save','hardware');
% opengl('software');

%--------------------------------------------------------------------------
% insert paths to images and value of colour channel
input = ('d:\cell_1_4856_1_3246\vienna_40-100\roi\'); % insert path to original RAW images without background
% alpha = [0.5, 0.99, 2]; % insert value of alpha for calculation of PDG-Whole
% % % step = 10;
% % % px = 1;
step = 130;
px = 64;
%--------------------------------------------------------------------------
for alpha = [7]
flrCell = dir([input,'*.png']);
flrPDG = dir([input,'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\*.mat']);
load([input, 'bgMod.mat'], 'modus'); % load values of the mode of the background
% load([input, 'envelope.mat']); % load values of the envelope

Cell = imread([input, flrCell(1).name]);
DARK = uint16(zeros(size(Cell, 1)/2, size(Cell, 2)/2, length(flrCell)-1));
BRIGHT = DARK;
BG = DARK;

wait = waitbar(0, 'Being processed');

for j = 3
    waitbar(j/3);
    
    for i = 2:length(flrPDG)
        Cell = imread([input, flrCell(i).name]); %%%           % read image of the cell
        Cell2 = Cell;
        
        % debayerize the color channels and read PDG matrices
        if j == 1
            Cell2 = Cell2(2:2:end,1:2:end-1);
            PDG2 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i).name]);
            PDG2 = PDG2.PDG_channel_1 == 0;
            PDG1 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i-1).name]);
            PDG1 = PDG1.PDG_channel_1 == 0;
        elseif j == 2
            Cell2 = (Cell2(1:2:end-1,1:2:end-1) + Cell2(2:2:end,2:2:end))/2;
            PDG2 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i).name]);
            PDG2 = PDG2.PDG_channel_2 == 0;
            PDG1 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i-1).name]);
            PDG1 = PDG1.PDG_channel_2 == 0;
        else, Cell2 = Cell2(1:2:end-1,2:2:end);
            PDG2 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i).name]);
            PDG2 = PDG2.PDG_channel_3 == 0;
            PDG1 = load([input, 'PDG_RGB-Whole-(', num2str(alpha, '%.4f'),')\', flrPDG(i-1).name]);
            PDG1 = PDG1.PDG_channel_3 == 0;
        end
        
        % create a binary mask from 2 parallel PDG images for exporting organelles
        BM = uint16(im2bw(PDG1 + PDG2, 0));
        clear PDG1 PDG2;
        
        % remove pixels with higher/smaller (and equal) intensity than mode of background from the image of cell
        Cell3 = Cell2;
        Cell4 = Cell2;
        Cell2(Cell2 >= modus(i,j)) = 0;
        Cell3(Cell3 <= modus(i,j)) = 0;
        Cell4(Cell4 ~= modus(i,j)) = 0;
        
        DARK(:,:,i-1) = (Cell2 .* BM); %.* uint16(envelope(:,:,i));
        BRIGHT(:,:,i-1) = (Cell3 .* BM); %.* uint16(envelope(:,:,i));
        BG(:,:,i-1) = (Cell4 .* BM); %.* uint16(envelope(:,:,i));
    end
    
    clear BM Cell Cell2 Cell3 Cell4;
    
    if ~exist([input, 'Results_' , num2str(alpha)], 'dir')
        mkdir([input, 'Results_' , num2str(alpha)]);
    end
    
    save([input, 'Results_' , num2str(alpha), '\Matrix_', num2str(j), '.mat'], 'DARK', 'BRIGHT', 'BG');
    
    % create a colormap for each color channel
    cmap = colormap(gray(256));
    
    if j == 1
        cmap(:, 2:3) = 0;
    elseif j == 2
        cmap(:, [1,3]) = 0;
    else cmap(:, 1:2) = 0;
    end
% % %     level2 = max(max(max(DARK))); %%%
% % %     level1 = min(min(nonzeros(DARK))); %%%
    
    % decompose the matrix according to the intensities
    string = cellstr(char('BRIGHT ', 'DARK ', 'BG '));
    
    for matrix = 2
        U = unique(eval(string{matrix}));
        
        if matrix == 1
            int = 1:(length(U)-1);
        else, int = [1, length(U):(-1):3];
        end
        
        for i = int
            
            if matrix == 1
                BRIGHT(BRIGHT == U(i)) = 0;
            elseif matrix == 2
                DARK(DARK == U(i)) = 0;
            else, BG(BG == U(i)) = 0;
            end
            
            graph = figure;
            vol3d('cdata', eval(string{matrix}),'texture','3D');
            view(3);
%             view(0, 30);
%             view(3);
%             view(-37.5, 60);
            zoom('out');
%             zoom(0.8);
%             caxis([0,4095]);
%             colormap(cmap);
            caxis([min(min(min(nonzeros(eval(string{matrix}))))),max(max(max(eval(string{matrix}))))]);
            colormap(jet);
% % %             caxis([level1, level2]);
%             colormap(jet);
%             alphamap('vup');
%             alphamap(.1.*alphamap);
            grid off;
            daspect([1 1 (1 - step/px/100)]);
            xlabel('[nm]');
            ylabel('[nm]');
            zlabel('[nm]');
            newTicks([px, px, step]);
            set(get(gca,'XLabel'), 'Units', 'Normalized', 'Position', [-0.3, 0.1, 0]); % change the vector of position of units, if needed
            set(get(gca,'YLabel'), 'Units', 'Normalized', 'Position', [1.3, 0.1, 0]); % change the vector of position of units, if needed
            
            if ~exist([input, 'Results_' , num2str(alpha), '\', num2str(j) '_', string{matrix}], 'dir')
                mkdir([input, 'Results_' , num2str(alpha), '\', num2str(j) '_', string{matrix}]);
            end
            
            hgexport(graph, [input, 'Results_' , num2str(alpha), '\', num2str(j), '_', string{matrix}, '\', num2str(j), '_', num2str(U(i), '%04i'), '_', string{matrix}, '.png'], hgexport('factorystyle'), 'Format', 'png');
            %         saveas(graph, [inputCell, 'Results\', num2str(j), '_', string{matrix}, '\', num2str(j), '_', num2str(U(i), '%04i'), '_', string{matrix}, '.fig']);
%                 saveas(graph, [inputCell, 'Results\', num2str(j), '_', string{matrix}, '\', num2str(j), '_', num2str(U(i), '%04i'), '_', string{matrix}, '.png']);
%            clf;
            close all;
        end
        
        if matrix == 1
            clear BRIGHT;
        elseif matrix == 2
            clear DARK;
        end
    end
end
end
close(wait);