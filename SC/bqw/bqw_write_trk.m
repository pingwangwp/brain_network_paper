function bqw_write_trk(hdr,fibers)
% Format: bqw_write_trk(hdr,fibers)
% ===========================================================
% Inputs:
%    hdr: Header information [struc] for .trk file 
%    fibers: fiber data struc array [nFib,1]
%            - coord; XYZ coordinates (in mm) and associated scalars
%            - nPoints; No. of points in each fiber
%            - props: diffusion scalars
% ================Wrtten by QinWen 20180422==================
if nargin<2
    fprintf('================Write fiber tracking file (.trk)===================\n');
    fprintf('Format: bqw_write_trk(hdr,fibers)\n'); 
    fprintf('Input:\n --hdr: fiber header (for detail, type ''help bqw_read_trk'')\n');
    fprintf(' --fibers:fiber data structure (nFib)\n');
    fprintf('   fibers.coord: XYZ coordinates(mm) and assciated scalars\n   fibers.nPoints: number of points in each fiber\n');
    fprintf('   fibers.props:   diffusion scalars\n');
    fprintf('----------------Written by QinWen 20180808 -----------------------\n');
    return
end
if ~isfield(hdr,'trkpath');
    hdr.trkpath=[pwd,filesep,hdr.id_string,'.trk'];
end
fid = fopen(hdr.trkpath, 'w');
% Write hdr
fwrite(fid, hdr.id_string, '*char');
fwrite(fid, hdr.dim, 'short');
fwrite(fid, hdr.voxel_size, 'float');
fwrite(fid, hdr.origin, 'float');
fwrite(fid, hdr.n_scalars , 'short');
fwrite(fid, hdr.scalar_name', '*char');
fwrite(fid, hdr.n_properties, 'short');
fwrite(fid, hdr.property_name', '*char');
fwrite(fid, hdr.vox_to_ras', 'float');
fwrite(fid, hdr.reserved, '*char');
fwrite(fid, hdr.voxel_order, '*char');
fwrite(fid, hdr.pad2, '*char');
fwrite(fid, hdr.image_orientation_patient, 'float');
fwrite(fid, hdr.pad1, '*char');
fwrite(fid, hdr.invert_x, 'uchar');
fwrite(fid, hdr.invert_y, 'uchar');
fwrite(fid, hdr.invert_z, 'uchar');
fwrite(fid, hdr.swap_xy, 'uchar');
fwrite(fid, hdr.swap_yz, 'uchar');
fwrite(fid, hdr.swap_zx, 'uchar');
fwrite(fid, hdr.n_count, 'int');
fwrite(fid, hdr.version, 'int');
fwrite(fid, hdr.hdr_size, 'int');
%Write data
for n = 1:hdr.n_count
    % Modify orientation back to LPS for display in TrackVis
    coords = fibers(n).coord(:,1:3);
    fibers(n).coord(:,1:3) = coords;    
    fwrite(fid, fibers(n).nPoints, 'int');
    fwrite(fid, fibers(n).coord', 'float');
    if hdr.n_properties
        fwrite(fid, fibers(n).props, 'float');
    end
end
fclose(fid);

