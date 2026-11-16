function bqw_write_nii(vol,img,pile)
%=======================================================================
%% Format: bqw_write_nii(vol,img,pile);
%=======================================================================
% %% write image matrix into nifti files
% vol: spm volume structure saving the header information.
% img: image matrix.
% pile; pile into one 4D (3D) file: 'yes'(default) ;
% ______________Written by QIN WEN at 2018-03-31________________________
% =======================================================================
if nargin<3
    pile='yes';
end
if nargin<2
    fprintf('=================<<write nifti files>>=======================\n');
    fprintf('Format: bqw_write_nii(vol,img,opt)\n');
    fprintf('--vol: spm volume structure saving the header information\n');
    fprintf('--img: image matrix, can be 2D, 3D or 4D\n');
    fprintf('--pile; pile into one 4D(3D) file: ''yes''(default)\n');
    fprintf('-------------Written by QIN WEN at 2018-03-31----------------\n');
    return;
end
dim=size(img);
ndim=length(dim);
vdim=vol(1).dim;
if vdim(3)==1;nvdim=2;else nvdim=3;end;
[outdir,filename,ext]=fileparts(vol(1).fname);
if isempty(outdir)
outdir=pwd;
end

if strcmp(ext,'.gz');
    vol(1).fname=[outdir,filesep,filename];
end
if ndim==nvdim;
    if all(dim==vdim(1:ndim))
        spm_write_vol(vol,img);
        if strcmp(ext,'.gz')
            gzip(vol.fname);
            delete(vol.fname);
        end
    else
        error('header dimension[%s] mismatch with image [%s]\n',num2str(vdim),num2str(dim));
    end
elseif (ndim-nvdim)==1
    if all(dim(1:nvdim)==vdim)
        for t=1:dim(ndim)
            if strcmp(pile,'yes')
                volt=vol(1);
                volt.n=[t,1];
                volt.pinfo(3)=vol(1).pinfo(3)+prod(vdim)*2*(t-1);
            else
                volt=vol(1);
                if t<10
                    volt.fname=[outdir,filesep,filename,'_000',num2str(t),ext];
                elseif t<100
                    volt.fname=[outdir,filesep,filename,'_00',num2str(t),ext];
                elseif t<1000
                    volt.fname=[outdir,filesep,filename,'_0',num2str(t),ext];
                else
                    volt.fname=[outdir,filesep,filename,'_',num2str(t),ext];
                end
            end
            if ndim==3
                spm_write_vol(volt,img(:,:,t));
            elseif ndim==4
                spm_write_vol(volt,img(:,:,:,t));
            end            
        end
        if strcmp(ext,'.gz')
            gzip(vol(1).fname);
            delete(vol(1).fname);
        end
    else
        error('header dimension[%s] mismatch with image [%s]\n',num2str(vdim),num2str(dim));
    end
end






