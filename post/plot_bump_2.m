clear all
close all
clc


smallfont = 10;
bigfont = 10;

room_for_sgtitle = 0.03;
room_for_labels = 0.01;

%positions/size of subplots including labels
x_lab = linspace( 0+room_for_labels, 1, 4+1 ) ;
x_lab = x_lab(1:end-1);
w_lab = 1 * diff( x_lab(1:2) ) ;
y_lab = linspace( 0+room_for_labels, 1-room_for_sgtitle, 4+1 ) ;
y_lab = y_lab(1:end-1);
h_lab = 1 * diff( y_lab(1:2) ) ;

%positions/size of subplots excluding labels
x = x_lab + room_for_labels;
w = w_lab - room_for_labels*2;
y = y_lab + room_for_labels;
h = h_lab - room_for_labels*2;


figure( 'Units', 'normalized', 'Position', [0.4, 0.4, 0.6, 0.6], ...
    'Color', 'white' ) ;
% - Bg axes and main title.
bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1] ) ;
text( 0.5, 0.99, 'A Small Example', 'FontSize', bigfont, ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold' ) ;

%- Headers for array still in bgAxes.
for colId = 1 : numel( x )
    for rowId = 1 : numel( y )
        text( x_lab(colId)+w_lab/2, y_lab(rowId), sprintf( 'Label X%d', colId ), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', smallfont ) ;
        text( x_lab(colId), y_lab(rowId)+h_lab/2, sprintf( 'Label Y%d', rowId ), ...
            'HorizontalAlignment', 'center', 'Rotation', 90, 'FontWeight', 'bold', 'FontSize', smallfont) ;
    end
end

% - Array of plots.
for colId = 1 : numel( x )
    for rowId = 1 : numel( y )
        ax1 = axes( 'Position', [x(colId), y(rowId), w, h] ) ;
        plot( sin( rand(1) * (1:10)), 'b' ) ;
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
    end
end
% 
% % - Surface.
% axes( 'Position', [0.65, 0.45, 0.3, 0.45] ) ;
% [X, Y] = meshgrid( -5: .5 : 5 ) ;
% Z = Y.*sin(X) - X.*cos(Y) ;
% s = surf(X,Y,Z,'FaceAlpha',0.5) ;
% s.EdgeColor = 'none';
% 
% % - Time series
% axes( 'Position', [0.05, 0.72, 0.515, 0.15] ) ;
% x = linspace( 0, 10, 100 ) ;
% plot( rand(size(x)) +  3 * sin(x) .* exp(-x/5), 'r' ) ;
% xlabel( 't [s]' ) ;
% ylabel( 'A [V]' ) ;
% grid( 'on' ) ;
% 
% % - Barchart.
% axes( 'Position', [0.65, 0.05, 0.3, 0.3] ) ;
% histogram( randn(1000, 1) ) ;
% set( gca, 'Box', 'off' ) ;
% 
% 
