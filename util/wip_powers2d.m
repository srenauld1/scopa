                
            if do3d
                [tmp, centmp, bin_prctiles] = probability_bin([masky, maskx, maskz], numroiauto, 1); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results
            else
                uz = unique(maskz);
                for uzi = 1:numel(uz)
                    zinds_each{uzi} = find(maskz==uz(uzi));
                    num_vox_each_slice(uzi) = numel(zinds_each{uzi});
                    frac_vox_each_slice(uzi) = num_vox_each_slice(uzi) / numel(maskz);
                    frac_mroi_auto_each_slice(uzi) = frac_vox_each_slice(uzi) * numroiauto;
                end
                rnds = pow2(round(log2(frac_mroi_auto_each_slice))); %rnds = round(frac_mroi_auto_each_slice);
                
                num_mroi_change = sum(rnds);
                numroiauto = num_mroi_change;

                tmp = zeros([numel(masky) 2], 'uint16');
                centmp = [];
                bin_prctiles = [];
                for i = 1:numel(rnds)
                    [tmp_xy, centmp_xy, bin_prctiles_xy] = probability_bin([masky, maskx], rnds(i), 1); %iteratively median split along dimension of greatest variance, ties are randomly assigned, so as of 240509, results are not reproducible, although differences are typically not major; so for reproducibility, pipeline loads saves/loads previous results
                    tmp(zinds_each{uzi},:) = tmp_xy;
                    centmp = [centmp centmp_xy];
                    bin_prctiles = [bin_prctiles bin_prctiles_xy];
                end
            end
            if size(unique(tmp.', 'rows'), 1)~=1
                error("each row must have constant value")
            end
            idx_vox2roi = tmp(:,1);
            centmp = centmp.';
            