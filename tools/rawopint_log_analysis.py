import csv
import re

class RawOpData:
    # these column lists included some columns only present in newer versions
    # filtered in constructor below
    all_apex96_cols=['sv96','tv96','av96','bv96','meter96','meter96_tgt','bv_ev_shift']
    all_frac_cols=['over_frac','under_frac']
    all_weight_cols=['meter_weight','over_weight','under_weight']
    all_ev_change_cols=['d_ev_base','d_ev_s1','d_ev_s2','d_ev_f','d_ev'] #apex96, but smaller values, some non-integer
    def __init__(self,fname):
        self.rows=[]
        self.cols={}

        with open(fname) as fh:
            i = 0
            for r in csv.DictReader(fh):
                # first data row is preshoot values, not a shot, some values missing
                # TODO handle multiple runs in a single file
                if i == 0:
                    self.preshoot_row = r
                elif r['start'] == '': # keyboard and other exit conditions leave partial row
                    self.quit_row = r
                    break
                else:
                    self.rows.append(r)
                i+=1
        self.len = len(self.rows)

        for name in self.rows[0]:
            if name in {'date','time','desc'}:
                self.cols[name] = [r[name] for r in self.rows]
            elif name in set(self.all_apex96_cols) or name in set(self.all_weight_cols) or name=='exp':
                self.cols[name] =[ None if r[name] == '' else int(r[name]) for r in self.rows]
            else:
                self.cols[name] =[ None if r[name] == '' else float(r[name]) for r in self.rows]

            # convenience data.col_name for interactive stuff
            setattr(self,name,self.cols[name])

        # make column lists for this instance to support older versions
        self.apex96_cols = [x for x in self.all_apex96_cols if x in self.cols]
        self.frac_cols = [x for x in self.all_frac_cols if x in self.cols]
        self.weight_cols = [x for x in self.all_weight_cols if x in self.cols]
        self.ev_change_cols = [x for x in self.all_ev_change_cols if x in self.cols]

        self.apex96_min = None
        self.apex96_max = None
        for name in self.apex96_cols:
            for v in self.cols[name]:
                if v is None:
                    continue
                if self.apex96_min is None:
                    self.apex96_min = v
                elif v < self.apex96_min:
                    self.apex96_min = v

                if self.apex96_max is None:
                    self.apex96_max = v
                elif v > self.apex96_max:
                    self.apex96_max = v

        self.parse_init_vals()

    # find the maximum value in a column and return the value, index and image number
    def find_max(self,colname):
        m = None
        m_i = None
        for i,v in enumerate(self.cols[colname]):
            if not m or v > m:
                m = v
                m_i = i
        return m, m_i, self.cols['exp'][m_i]

    def find_min(self,colname):
        m = None
        m_i = None
        for i,v in enumerate(self.cols[colname]):
            if not m or v < m:
                m = v
                m_i = i
        return m, m_i, self.cols['exp'][m_i]

    def parse_init_vals(self):
        self.init_vals = {}
        for chunk in [x.strip() for x in self.preshoot_row['desc'].split('/')]:
            chunk_parts = chunk.split(':',1)
            nm = chunk_parts[0]
            if len(chunk_parts) > 1:
                rest = chunk_parts[1]
            else:
                rest = None
            if nm == 'init':
                for k,val in [s.split('=') for s in rest.split(' ')]:
                    self.init_vals[k]=val
            elif nm == 'rawopint v':
                self.init_vals['rawopint_version'] = rest
            elif nm == 'platform':
                plat,build = rest.split(' ',1)
                self.init_vals['platform'],self.init_vals['platform_sub'],self.init_vals['chdk_version'] = plat.split('-',2)
                self.init_vals['build_date'] = build
            else:
                # hacky for inconsistent formatting
                c = chunk.count(':')
                # multiple : fields, assume space delimited
                if c > 1:
                    for s in chunk.split(' '):
                        parts=s.split(':')
                        if len(parts) == 2:
                            self.init_vals[parts[0]]=parts[1]
                        else:
                            self.init_vals[parts[0]]=True
                elif c==1:
                    parts=chunk.split(':')
                    self.init_vals[parts[0].replace(' ','_')] = parts[1]
                else:
                    self.init_vals[chunk.replace(' ','_')] = True

        init_frame=self.rows[0]['desc'].split('/')[0]
        chunk=init_frame.split(':',1)[1].strip()
        for s in chunk.split(' '):
            parts=s.split('=')
            if len(parts) == 2:
                self.init_vals[parts[0]]=parts[1]
            else:
                self.init_vals[parts[0]]=True

        for k,v in self.init_vals.items():
            if v == 'true':
                self.init_vals[k]=True
            elif v == 'false':
                self.init_vals[k]=False
            elif type(v) == str and re.match('-?[0-9]+$',v):
                self.init_vals[k]=int(v)
        self.start_date=self.cols['date'][0]
        self.start_time=self.cols['time'][0]
        self.start_exp=self.cols['exp'][0]

        self.end_date=self.cols['date'][-1]
        self.end_time=self.cols['time'][-1]
        self.end_exp=self.cols['exp'][-1]

    def fmt_ini_ev96(self,name):
        return f'{self.init_vals[name]/96:0.3g} ({self.init_vals[name]})'

    def summary(self):
        print(f"{self.init_vals['platform']}-{self.init_vals['platform_sub']}"
              f" {self.init_vals['chdk_version']} rawopint {self.init_vals['rawopint_version']}")
        print(f"{len(self.rows)} frames, {self.init_vals['interval']/1000}s interval,"
              f" {self.start_date} {self.start_time} - {self.end_date} {self.end_time},"
              f" shot {self.start_exp:04d} - {self.end_exp:04d}")
        print(f"ev_change_max: {self.fmt_ini_ev96('ev_change_max')}"
              f" ev_shift: {self.fmt_ini_ev96('ev_shift')} ev_use_initial:{self.init_vals['ev_use_initial']}")
        if self.init_vals['bv_ev_shift_pct'] == 0:
            print("bv ev shift: Off")
        else:
            print(f"bv ev shift: {self.init_vals['bv_ev_shift_pct']}%"
                  f" base: {self.fmt_ini_ev96('bv_ev_shift_base_bv') if self.init_vals['bv_ev_shift_base_bv'] else 'First'}")
        if 'smooth_factor' in self.cols:
            print(f"smooth factor: {self.init_vals['smooth_factor']/1000}"
                  f" limit: {self.init_vals['smooth_limit_frac']/1000}"
                  f" rev: {self.init_vals['ev_change_rev_frac']/1000}")

        print(f"over thresh: {self.init_vals['over_thresh_frac']/10000}% margin: {self.fmt_ini_ev96('over_margin_ev')}")
        print(f"under thresh: {self.init_vals['under_thresh_frac']/10000}%  margin: {self.fmt_ini_ev96('under_margin_ev')}")
        print(f"meter high thresh: {self.fmt_ini_ev96('meter_high_thresh')}"
              f" limit: {self.fmt_ini_ev96('meter_high_limit')}"
              f" weight: {self.init_vals['meter_high_limit_weight']}")
        print(f"meter low thresh: {self.fmt_ini_ev96('meter_low_thresh')}"
              f" limit: {self.fmt_ini_ev96('meter_low_limit')}"
              f" weight: {self.init_vals['meter_low_limit_weight']}")


