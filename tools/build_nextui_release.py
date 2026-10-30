"""Package a pinned upstream port with NextUI launchers. Never read SD game files."""
import argparse,hashlib,json,pathlib,stat,urllib.request,zipfile
VERSION='2026.10.31'
UPSTREAM='https://github.com/wild1walker/portmaster-cuphead/releases/download/2026.10.28.3/cuphead.zip'
EXPECTED='a2966708affa46f4d6b3ca02c40466c22c23f79a9af41b7df88c39cf101b1e7e'
DONORS={'cuphead/donor/donor-2017.4.40f1-mono-armv7.apk','cuphead/donor/donor-2017.4.9f1-mono-armv7.apk','cuphead/donor/donor-2017.4.40f1-il2cpp-arm64.apk'}
def sha(data):return hashlib.sha256(data).hexdigest()
def audit(name):
 p=pathlib.PurePosixPath(name)
 if p.is_absolute() or '..' in p.parts or '\\' in name or (p.parts and ':' in p.parts[0]):raise ValueError('Unsafe archive path')
 if name!='Cuphead.sh' and (not p.parts or p.parts[0]!='cuphead'):raise ValueError('Unexpected archive root: '+name)
 if len(p.parts)>1 and p.parts[1].lower() in {'arm64','data','userdata','home','reports','assets','saves'}:raise ValueError('Game/user data path: '+name)
 if name.startswith('cuphead/gamedata/') and name!='cuphead/gamedata/PUT_GAME_FILES_HERE.txt':raise ValueError('Game import: '+name)
 if p.suffix.lower() in {'.obb','.pkg','.mpq','.log'} or p.name.startswith('.cuphead_ready'):raise ValueError('Game/session file: '+name)
 if p.suffix.lower()=='.apk' and name not in DONORS:raise ValueError('Non-donor APK: '+name)
def write_zip(path,files,modes):
 with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for name,data in sorted(files.items()):
   audit(name)
   i=zipfile.ZipInfo(name,(2026,10,31,0,0,0));i.create_system=3
   i.external_attr=(stat.S_IFREG|modes.get(name,0o644))<<16
   i.compress_type=zipfile.ZIP_DEFLATED;z.writestr(i,data)
 with zipfile.ZipFile(path) as z:
  assert z.testzip() is None
  for n in z.namelist():audit(n)
def main():
 a=argparse.ArgumentParser();a.add_argument('--output',default='dist');a.add_argument('--upstream-zip',type=pathlib.Path);args=a.parse_args()
 root=pathlib.Path(__file__).resolve().parents[1];out=pathlib.Path(args.output).resolve();out.mkdir(parents=True,exist_ok=True)
 source=args.upstream_zip or out/'upstream.zip'
 if not source.exists():urllib.request.urlretrieve(UPSTREAM,source)
 if sha(source.read_bytes())!=EXPECTED:raise ValueError('Upstream SHA256 mismatch')
 files={};modes={}
 with zipfile.ZipFile(source) as z:
  for i in z.infolist():
   if i.is_dir():continue
   audit(i.filename)
   if stat.S_ISLNK(i.external_attr>>16):raise ValueError('Unexpected symlink')
   if i.filename in files:raise ValueError('Duplicate ZIP entry')
   files[i.filename]=z.read(i);modes[i.filename]=(i.external_attr>>16)&0o777
 for dest,src in [('Cuphead.sh','pm/cuphead/Cuphead.sh'),('cuphead/launch64.sh','pm/cuphead/cuphead/launch64.sh')]:
  files[dest]=(root/src).read_bytes();modes[dest]=0o755
  if b'\r' in files[dest]:raise ValueError('Launcher must use LF newlines')
 files['cuphead/README-NextUI.txt']=(root/'README-NextUI.txt').read_bytes()
 files['cuphead/licenses/LICENSE.nextui.txt']=(root/'LICENSE').read_bytes()
 files['cuphead/nextui-release.json']=(json.dumps({'release':VERSION,'upstream_version':'2026.10.28.3','upstream_url':UPSTREAM,'upstream_sha256':EXPECTED,'game_data_included':False},indent=2)+'\n').encode()
 files['cuphead/nextui-release-files.sha256']=''.join(sha(data)+'  '+name+'\n' for name,data in sorted(files.items())).encode()
 patch_names={'Cuphead.sh','cuphead/launch64.sh','cuphead/README-NextUI.txt','cuphead/licenses/LICENSE.nextui.txt'}
 artifacts=[out/('cuphead-nextui-'+VERSION+'.zip'),out/('cuphead-nextui-scripts-'+VERSION+'.zip')]
 write_zip(artifacts[0],files,modes);write_zip(artifacts[1],{n:files[n] for n in patch_names},modes)
 (out/'SHA256SUMS.txt').write_text(''.join(sha(p.read_bytes())+'  '+p.name+'\n' for p in artifacts),encoding='utf-8',newline='\n')
 print(json.dumps({'checked_files':len(files),'script_package_files':len(patch_names),'assets':[{'name':p.name,'bytes':p.stat().st_size,'sha256':sha(p.read_bytes())} for p in artifacts]},indent=2))
if __name__=='__main__':main()
