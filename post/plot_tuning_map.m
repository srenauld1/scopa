

function plot_tuning_map(plottuning, filename_caimanrois)


response_metric_unit = 'signal_plus_noise';
nrows = 2;
methods = {'mean'};


figure;

textHandle = suptitle( {'direction maps'} );
set( textHandle, 'Interpreter', 'none' );

for methodind = 1 : numel( methods )


    subplot( nrows, numel( methods ), methodind );
    hold on;
    title( ['vector average (polar)'], 'Interpreter', 'none' );
    hsvmap = FormHSV( mod( tcParamsVectorAveragePlot{methodind}.bestDir, 360 ), [0 360] );
    hsvmap(:, :, 1) = mod( hsvmap(:, :, 1) + 60/360, 1 );
    image( hsv2rgb( hsvmap ) );
    if methodind == numel( methods )
        colormap( circshift( hsv(360), -60, 1 ) );
        colorbar;
    end
    set(gca, 'Position', get(gca, 'OuterPosition') - ...
        get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
    axis image;
    axis ij;
    hold off;

    subplot( nrows, numel( methods ), 1 * numel( methods ) + methodind );
    hold on;
    title( ['vector average (HLS)'], 'Interpreter', 'none' );
    vData = abs( tcParamsNonparametricPlot{methodind}.extremeResp );
    switch response_metric_unit
        case 'signal'
            vRange = [0 0.5];
        case {'response_metric_unit', 'response_by_time'}
            vRange = [0 prctile( vData(:), 99 )];
    end

    hsvmap = FormHSV( mod( tcParamsVectorAveragePlot{methodind}.bestDir, 360 ), [0 360], ...
        real(tcParamsVectorAveragePlot{methodind}.tuningInd), [0 1], ...
        vData, vRange );
    hsvmap(:, :, 1) = mod( hsvmap(:, :, 1) + 60/360, 1 );
    image( hsv2rgb( hsvmap ) );

    axis image;
    axis ij;
    hold off;

end
