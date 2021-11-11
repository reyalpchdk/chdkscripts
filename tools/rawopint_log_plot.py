# Copyright 2021 reyalp (at) gmail.com

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# with this program. If not, see <http://www.gnu.org/licenses/>.

from rawopint_log_analysis import RawOpData
import matplotlib.pyplot as plt

class RawOpDataPlot(RawOpData):
    '''RawOpdata subclass with plotting so main module doesn't need matplotlib'''
    def plot_format_coord(self,x, y, cols):
        '''
        add user selectable values from the run data to "label" text below the plot
        when using interactive backend. Y and shot number are included by default.
        '''


        x = int(round(x))
        s = f'y:{y:.2f}'
        if x > 0 and x < self.len:
            s += f' shot:{x}'
            for cname in cols:
                if cname in self.cols:
                    v = self.cols[cname][x]
                    if v == '' or v is None:
                        v = '-'
                    s += f' {cname}:{v}'
                else:
                    s += f' (unk {cname})'

        return s


    def plot(self, names, ylabel = None, xlabel='shot', label_cols = ['exp'], **plot_options):
        '''
        plot csv columns specified by 'names', which may be either a single string or array of strings
        'label_cols' is an array of column names to show hover values for below the plot. None to disable
        'plot_options' are passed to Axes plot
        '''
        if type(names) == str:
            names = [names]

        fig, ax = plt.subplots()
        lines = []
        for name in names:
            lines.append(ax.plot(self.cols[name],label=name, **plot_options)[0])
        ax.set_xlabel(xlabel)
        if ylabel:
            ax.set_ylabel(ylabel)

        if label_cols:
            ax.format_coord = lambda x,y: self.plot_format_coord(x, y, label_cols)

        # make legend toggle plots when using widget, based on
        # https://matplotlib.org/stable/gallery/event_handling/legend_picking.html#sphx-glr-gallery-event-handling-legend-picking-py
        leg = ax.legend()
        leglines = leg.get_lines()
        linemap = {}
        for i,legline in enumerate(leglines):
            legline.set_picker(True)
            linemap[legline] = lines[i]

        def on_leg_pick(event):
            legline = event.artist
            line = linemap[legline]
            # bug - this doesn't honor lines original alpha
            if line.get_visible():
                line.set_visible(False)
                legline.set_alpha(0.5)
            else:
                line.set_visible(True)
                legline.set_alpha(1.0)
            fig.canvas.draw()

        fig.canvas.mpl_connect('pick_event',on_leg_pick)

    def plot_group(self, group, **kwargs):
        '''
        plot all columns from one of the column groups defined in RawOpData.col_groups
        kwargs passed to RawOpDataPlot.plot
        '''
        if not group in self.col_groups:
            raise ValueError(f'unknown group {group}')
        if 'ylabel' not in kwargs:
            kwargs['ylabel'] = group
        self.plot(getattr(self,group+'_cols'),**kwargs)
