function [fibers,hdr] = bqw_read_trk(trkpath)
% Format: [fibers,hdr] = bqw_read_trk(trkpath)
% ===========================================================
% Read TrackVis or DSI_STUDIO .trk (or .trk.gz) file
% --trkpath: fiber filepath (string)
% --fibers: 
%            - coord; XYZ coordinates (in mm) and associated scalars
%            - nPoints; No. of points in each fiber
%            - props: diffusion scalars
% --hdr: fiber header file
%		     - hdr.id_string               - ID string for track file.The first 5 characters must be "TRACK".
%            - hdr.dim                     - Dimension of the image volume.
%	         - hdr.voxel_size              - Voxel size of the image volume.
%		     - hdr.orgin                   - Origin of the image volume.
%                                     		   This field is not yet being used by TrackVis.
%                                        	   That means the origin is always (0, 0, 0).
%            - hdr.n_scalars               - Number of scalars saved at each track point (besides x, y and z coordinates).
%		     - hdr.scalar_name             - Name of each scalar. Can not be longer than 20 characters each. Can only store up to 10 names.
%		     - hdr.n_properties            - Number of properties saved at each track.
%		     - hdr.property_name           - Name of each property.
%                                        	   Can not be longer than 20 characters each. Can only store up to 10 names.
%            - hdr.vox_to_ras              - A 4x4 matrix for voxel to RAS (crs to xyz) transformation.
%                                        	   If vox_to_ras[3][3] is 0, it means the matrix is not recorded.
%            - hdr.reserved                - Reserved space for future version.
%		     - hdr.voxel_order             - Storing order of the original image data.
%		     - hdr.pad2                    - Paddings.
%		     - image_orientation_patient - Image orientation of the original image.
%		     - hdr.pad1                    - Paddings.
%            - hdr.invert_x                - Inversion/rotation flags used to generate this track file.
%            - hdr.invert_y                - As above
%            - hdr.invert_z                - As above
%            - hdr.swap_xy                 - As above.
%		     - hdr.swap_yz                 - As above.
%		     - hdr.swap_zx                 - As above.
%		     - hdr.n_count                - Number of fibers stored in this track file. 0 means the number was NOT stored.
%            - hdr.version                 - Version number of the trackvis.
%            - hdr.hdr_size                - Size of the hdr. Used to determine byte swap. Should be 1000.
%            - hdr.trkpath                 - fiber filepath
%            - hdr.trkpath                 - filepath of trackfile
if nargin==0
    fprintf('================Read fiber tracking file (.trk)===================\n');
    fprintf('Format: [fibers,hdr] = bqw_read_trk(trkpath)\n'); 
    fprintf('Input:\n --trkpath:fiber filepath (string)\n');
    fprintf('Output:\n --fibers:\n');
    fprintf('   fibers.coord:   XYZ coordinates(mm) and assciated scalars\n   fibers.nPoints: number of points in each fiber\n');
    fprintf('   fibers.props:   diffusion scalars\n  --hdr: fiber header (for detail, type ''help bqw_read_trk'')\n');
    fprintf('----------------Written by QinWen 20180808 -----------------------\n');
    return
end
[trkdir,trkname,ext]=fileparts(trkpath);
if isempty(trkdir); trkdir=pwd;end
if strcmp(ext,'.gz')
if ispc    
gunzip(trkpath);
trkpath=[trkdir,filesep,trkname];
elseif isunix
gunzip(trkpath,'/tmp/');
trkpath=['/tmp/',trkname];
end
end
fid    = fopen(trkpath, 'rb', 'l');
hdr = get_hdr(fid);
hdr.trkpath =trkpath;
% Check for byte order
% if hdr.hdr_size~=1000
%     fclose(fid);
%     fid    = fopen(trkpath, 'r', 'b'); % Big endian for old PPCs
%     hdr = get_hdr(fid);
% end
if hdr.hdr_size~=1000; error('Header length is wrong'), end
n = 0;
while feof(fid) == 0
    n = n + 1;
    nPoints= fread(fid, 1, 'int');
    if nPoints~=0
        fibers(n).nPoints = nPoints;
        fibers(n).coord  = fread(fid, [3+hdr.n_scalars, fibers(n).nPoints], '*float')';
%        fibers(n).coord  = double(fibers(n).coord./repmat(hdr.voxel_size,fibers(n).nPoints,1)); % convert mm coordinates into voxel ones
        if hdr.n_properties
            fibers(n).props=fread(fid,hdr.n_properties,'*float');
        end
    end
end
fibers=fibers';
if hdr.n_count == 0
    hdr.n_count = length(fibers);
end
fclose(fid);
if strcmp(ext,'.gz')
    delete(trkpath);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hdr = get_hdr(fid)

hdr.id_string                 = fread(fid, 6, '*char')';
hdr.dim                       = fread(fid, 3, 'short')';
hdr.voxel_size                = fread(fid, 3, 'float')';
hdr.origin                    = fread(fid, 3, 'float')';
hdr.n_scalars                 = fread(fid, 1, 'short')';
hdr.scalar_name               = fread(fid, [20,10], '*char')';
hdr.n_properties              = fread(fid, 1, 'short')';
hdr.property_name             = fread(fid, [20,10], '*char')';
hdr.vox_to_ras                = fread(fid, [4,4], 'float')';
hdr.reserved                  = fread(fid, 444, '*char');
hdr.voxel_order               = fread(fid, 4, '*char')';
hdr.pad2                      = fread(fid, 4, '*char')';
hdr.image_orientation_patient = fread(fid, 6, 'float')';
hdr.pad1                      = fread(fid, 2, '*char')';
hdr.invert_x                  = fread(fid, 1, 'uchar');
hdr.invert_y                  = fread(fid, 1, 'uchar');
hdr.invert_z                  = fread(fid, 1, 'uchar');
hdr.swap_xy                   = fread(fid, 1, 'uchar');
hdr.swap_yz                   = fread(fid, 1, 'uchar');
hdr.swap_zx                   = fread(fid, 1, 'uchar');
hdr.n_count                   = fread(fid, 1, 'int')';
hdr.version                   = fread(fid, 1, 'int')';
hdr.hdr_size                  = fread(fid, 1, 'int')';
