#pragma rtGlobals=1		// Use modern global access method.

#ifndef WAVEUTILS_INCLUDE
#define WAVEUTILS_INCLUDE

#include "dictutils"
#include "refpathutils"

// TODO: write general wave extraction routine

Function Wave_appendRow(wave_in)
    // Add a new row to a wave and return the index of the new row
    Wave wave_in
    return Wave_appendRows(wave_in, 1)
End

Function Wave_appendRows(wave_in, number_rows_to_add)
    // Adds *number_rows_to_add* new rows to the end of the wave and
    // return the index of the first new row
    Wave wave_in
    Variable number_rows_to_add
    Variable last_row = Wave_getLastRowIndex(wave_in)
    InsertPoints/M=0 last_row+1, number_rows_to_add, wave_in
    return Wave_getLastRowIndex(wave_in)
End

Function Wave_removeRows(wave_in, start_i, end_i)
    // Removes rows from the start index *start_i* to the end index
    // *end_i* inclusive
    Wave wave_in
    Variable start_i, end_i

    Variable last_i = Wave_getLastRowIndex(wave_in)
    start_i = start_i >= 0 ? start_i : 0
    end_i = end_i <= last_i ? end_i : last_i
    DeletePoints/M=0 start_i, (end_i - start_i + 1), wave_in
End

Function Wave_appendColumns(wave_in, add_n)
    Wave wave_in
    Variable add_n
    return Wave_appendToDimension(wave_in, add_n, 1)
End

Function Wave_appendToDimension(wave_in, add_n, dim_num)
    Wave wave_in
    Variable add_n
    Variable dim_num

    Variable dim_size = Wave_getDimSize(wave_in, dim_num)
    InsertPoints/M=(dim_num) dim_size, add_n, wave_in
    return dim_size
End

Constant WAVEEXPAND_FACTOR = 0.1
Function Wave_expandRows(wave_in)
    // Adds a number of rows proportional to the total number of rows
    //   To mitigate memory fragmentation, add multiple rows at a time
    Wave wave_in
    Variable row_count = Wave_getRowCount(wave_in)
    Variable new_rows = row_count * WAVEEXPAND_FACTOR
    return Wave_appendRows(wave_in, new_rows)
End

Function Wave_getLastRowIndex(wave_in)
    Wave wave_in
    return Wave_getRowCount(wave_in) - 1
End

Function Wave_getRowCount(wave_in)
    Wave wave_in
    return Wave_getDimSize(wave_in, 0)
End

Function Wave_getColumnCount(wave_in)
    Wave wave_in
    return Wave_getDimSize(wave_in, 1)
End

Function Wave_getDimSize(wave_in, dim_num)
    Wave wave_in
    Variable dim_num

    if (dim_num > 4)
        dim_num = 4
    elseif (dim_num < 0)
        dim_num = 0
    endif

    Variable count = DimSize(wave_in, dim_num)
    if (isNaN(count))
        count = 0
    endif
    return count
End

Function/S Wave_getUniqueName(base_name)
    String base_name
    return UniqueName(base_name, 1, 0)
End

Function/WAVE Wave_getSubrange(wave_in, point_min, point_max)
	Wave wave_in
	Variable point_min, point_max

	Duplicate/FREE/R=[point_min,point_max] wave_in, wave_out
	return wave_out
End

Function/S Wave_getPath(wave_in)
    Wave wave_in
    return GetWavesDataFolder(wave_in, 2)
End

Function/S Wave_getDF(wave_in)
    Wave wave_in
    return GetWavesDataFolder(wave_in, 1)
End

Function/DF Wave_getDFR(wave_in)
    Wave wave_in
    return GetWavesDataFolderDFR(wave_in)
End

Function/S Wave_getDataUnits(wave_in)
    Wave wave_in
    return WaveUnits(wave_in, -1)
End

Function/S Wave_getRowUnits(wave_in)
    Wave wave_in
    return WaveUnits(wave_in, 0)
End

Function Wave_setDataUnits(wave_in, new_units)
    Wave wave_in
    String new_units

    SetScale d 0, 0, new_units, wave_in
End

Function Wave_setRowDelta(wave_in, new_delta)
    Wave wave_in
    Variable new_delta
    SetScale/P x Wave_getRowOffset(wave_in), new_delta, wave_in
End

Function Wave_setRowUnits(wave_in, new_units)
    Wave wave_in
    String new_units
    SetScale/P x Wave_getRowOffset(wave_in), Wave_getRowDelta(wave_in), new_units, wave_in
End

Function Wave_setRowOffset(wave_in, new_offset)
    Wave wave_in
    Variable new_offset
    SetScale/P x new_offset, Wave_getRowDelta(wave_in), wave_in
End

Function Wave_getRowDelta(wave_in)
    Wave wave_in
    return DimDelta(wave_in, 0)
End

Function Wave_getRowOffset(wave_in)
    Wave wave_in
    return DimOffset(wave_in, 0)
End

Function Wave2D_getColumnIndex(wave_in, onedim_index)
    // Return the column index in a 2D wave when given a 1D index
    Wave wave_in
    Variable onedim_index
    Variable row_count = Wave_getRowCount(wave_in)
    return floor(onedim_index / row_count)
End

Function Wave2D_getRowIndex(wave_in, onedim_index, col_index)
    // Return the row index in a 2D wave when given a 1D index
    Wave wave_in
    Variable onedim_index, col_index

    Variable row_count = Wave_getRowCount(wave_in)
    return (onedim_index - (col_index * row_count))
End

Function/WAVE Wave_convert2DToRowIndices(wave_ids, wave_orig)
    // Given a wave of 2D indices into `wave_orig`, convert input wave to row indices
    Wave wave_ids, wave_orig
    Duplicate/FREE wave_ids, wave_out
    wave_out = Wave2D_getRowIndex(wave_orig, wave_out, Wave2D_getColumnIndex(wave_orig, wave_out))
    return wave_out
End

Function/WAVE Wave_getSliceByX(wave_in, start_x, end_x)
    Wave wave_in
    Variable start_x, end_x
    Duplicate/FREE/R=(start_x, end_x) wave_in, wave_out
    return wave_out
End

Function/WAVE Wave_getSlice(wave_in, start_pt, end_pt)
	Wave wave_in
	Variable start_pt, end_pt
	Duplicate/FREE/R=[start_pt, end_pt] wave_in, wave_out

    String wave_note = Note(wave_in)
    String point_str
    sprintf point_str, "%d,%d", start_pt, end_pt
    wave_note = Dict_addItem(wave_note, "Slice", point_str)
    Note/K wave_out, wave_note
    return wave_out
End

Function Wave_saveSliceByX(wave_in, start_x, end_x, waveout_name)
    Wave wave_in
    Variable start_x, end_x
    String waveout_name
    Wave_saveSlice(wave_in, x2pnt(wave_in, start_x), x2pnt(wave_in, end_x), waveout_name)
End

/// Store a wave reference to a new location
//
// In particular, useful for saving a free wave.
//
// @param path      path for where to save new wave (e.g. root:folder:wavename)
// @param overwrite (default: false) if "true", overwrites existing waves
// @returns 0, if successful. -1, for error.
//
// TODO: allow for paths/datafolders that do not exist yet
Function Wave_store(wave_in, path, [overwrite])
    Wave wave_in
    String path
    Variable overwrite

    if (ParamIsDefault(overwrite))
        overwrite = 0
    endif

    // trying to store wave to itself is a no-op
    String old_path = Wave_getPath(wave_in)
    String new_path = RefPath_resolve(path)
    if (isStringsEqual(old_path, new_path))
        return 0
    endif

    if (overwrite && WaveExists($(new_path)))
        Duplicate/O wave_in, $(new_path)
        return 0
    endif

    if (!WaveExists($(new_path)))
        MoveWave wave_in, $(new_path)
        return 0
    endif

    return -1                   // encountered some error
End

Function Wave_saveSlice(wave_in, start_pt, end_pt, waveout_name)
    Wave wave_in
    Variable start_pt, end_pt
    String waveout_name

    Wave wave_out = Wave_getSlice(wave_in, start_pt, end_pt)
    Wave_store(wave_out, waveout_name, overwrite=1)
End

Function Wave_saveSliceFromGraph(waveout_name)
    String waveout_name
    Wave curr_wave = CsrWaveRef(A)
    Variable start_pt = pcsr(A)
    Variable end_pt = pcsr(B)
    Wave_saveSlice(curr_wave, start_pt, end_pt, waveout_name)
End

Function Wave_setPointToZeroX(wave_in, new_zero_pt)
    Wave wave_in
    Variable new_zero_pt

    SetScale/P x pnt2x(wave_in, 0)-pnt2x(wave_in, new_zero_pt), deltax(wave_in), wave_in
End

///
// Compares wave data for equality
//
// Checks wave data type, dimensions, and data. Currently ignores all
// other aspects of waves for the purposes of equality. The built-in
// EqualWaves returns true if either wave contains a zero point, so
// does not work for comparing data!
Function isWavesEqual(waveA, waveB, [tol])
    Wave/Z waveA, waveB
    Variable tol

    if (!WaveExists(waveA) || !WaveExists(waveB))
        return 0
    endif
    // compare data type and dimensions
    if (!EqualWaves(waveA, waveB, 514))
        return 0
    endif

    if (ParamIsDefault(tol))
        tol = 1e-12
    endif

    // compare data
    Duplicate/FREE waveA, comparator
    comparator = abs(waveA - waveB)
    comparator = comparator >= tol ? 1 : 0
    return (sum(comparator) == 0)
End

Function addWaves(waveA, waveB)
	Wave waveA, waveB
	waveB += waveA
End

Function addWaves_noNaNs(waveA, waveB)
    WAVE waveA
    WAVE waveB
    waveB += isNaN(waveA) ? 0 : waveA
End

// Make a new wave named *waveout_name* by reducing the sampling
// interval to *x_interval* and averaging over windows of size *x_avg*
// centered over each new point.
//
// Built-in functions like Resample are supposed to be able to handle
// this, but the options were confusing to me. See also the help topic
// "Decimation by Smoothing"
Function Wave_decimate(wave_in, x_interval, x_avg, waveout_name, [no_ends, start, stop])
    Wave wave_in
    String waveout_name         // name of wave to save results to

    Variable x_interval         // interval (in x units) between
                                // points in new wave
    Variable x_avg              // size (in x units) of window to average
                                // over for each point
    Variable no_ends            //
    Variable start
    Variable stop

    if (ParamIsDefault(no_ends))
        no_ends = 0
    endif

    Variable orig_start, orig_end
    Variable orig_delta = DimDelta(wave_in, 0)
    Variable orig_size = DimSize(wave_in, 0)

    if (ParamIsDefault(start))
        orig_start = DimOffset(wave_in, 0)
    else
        orig_start = start
    endif
    if (ParamIsDefault(stop))
        orig_end = orig_size*orig_delta + orig_start
    else
        orig_end = stop
    endif

    Variable half_window = x_avg / 2
    // Do not allow upsampling or interval values of 0
    if (x_interval < orig_delta)
        x_interval = orig_delta
    endif

    Variable new_start = orig_start
    Variable new_end = orig_end + x_interval
    if (no_ends > 0)
        new_start += half_window
        new_end -= half_window
    endif
    Variable new_size = floor(((new_end-new_start) / x_interval))

    Make/O/D/N=(new_size) $(waveout_name)
    Wave wave_out = $(waveout_name)
    SetScale/P x new_start, x_interval, WaveUnits(wave_in, 0), wave_out

    wave_out = mean(wave_in, x-half_window, x+half_window)
End

Function Wave_getLastX(wave_in)
    Wave wave_in
    return pnt2x(wave_in, Wave_getRowCount(wave_in)-1)
End

Function Wave_getFirstX(wave_in)
    Wave wave_in
    return DimOffset(wave_in, 0)
End

// Return a clipped copy of wave *wave_in* in a wave named
// *waveout_name* with values limited to the minimum value *min_y* and
// maximum value *max_y*. Values outside this range are clipped to
// *min_y* and *max_y*.
Function Wave_clip(wave_in, min_y, max_y, waveout_name)
    Wave wave_in
    Variable min_y, max_y
    String waveout_name

    Duplicate/O wave_in, $(waveout_name)
    Wave wave_out = $(waveout_name)
    wave_out = limit(wave_out, min_y, max_y)
End

// Return a clipped copy of wave *wave_in* in a wave named
// *waveout_name* with values limited to the minimum value *min_y* and
// maximum value *max_y*. Values outside this range are replaced with NaN.
Function Wave_clipToNaN(wave_in, min_y, max_y, waveout_name)
    Wave wave_in
    Variable min_y, max_y
    String waveout_name

    WaveSlice_clipToNaN(wave_in, 0, Wave_getRowCount(wave_in), min_y, max_y, waveout_name)
End

Function WaveSlice_clipToNaN(wave_in, start_pt, end_pt, min_y, max_y, waveout_name)
    Wave wave_in
    Variable start_pt, end_pt
    Variable min_y, max_y
    String waveout_name

    Wave_saveSlice(wave_in, start_pt, end_pt, waveout_name)
    Wave wave_out = $(waveout_name)
    wave_out = wave_out[p] < min_y ? NaN : wave_out[p]
    wave_out = wave_out[p] > max_y ? NaN : wave_out[p]
End

Function Wave_subtract(waveA, waveB, waveout_name)
    Wave waveA, waveB
    String waveout_name

    Duplicate/FREE waveA, wave_out
    wave_out = waveA - waveB
    Wave_store(wave_out, waveout_name)
End

Function/S Wave_NumsToList(wave_in)
    Wave wave_in

    String new_list = ""
    Variable row_count = Wave_getRowCount(wave_in)
    Variable i
    for (i=0; i<row_count; i+=1)
        new_list = List_addItem(new_list, num2str(wave_in[i]))
    endfor
    return new_list
End


// apply full wave rectification to wave_in (in-place)
// essentially flips all negative values to be positive
Function Wave_rectifyFull(wave_in, cut, [pol])
    Wave wave_in
    Variable cut
    String pol                  // polarity: "pos" (default) or "neg"
    if (ParamIsDefault(pol))
        pol = "pos"
    endif

    if (cmpstr("neg", pol) == 0) // flip positive values
        wave_in = wave_in < cut ? wave_in : -wave_in
    else                        // flip negative values
        wave_in = wave_in > cut ? wave_in : -wave_in
    endif
End

// apply half-wave rectification to wave_in (in-place)
Function Wave_rectifyHalf(wave_in, cut, [pol])
    Wave wave_in
    Variable cut
    String pol                  // polarity: "pos" (default) or "neg"
    if (ParamIsDefault(pol))
        pol = "pos"
    endif

    if (cmpstr("neg", pol) == 0) // no positive values
        wave_in = wave_in > cut ? cut : wave_in
    else                        // no negative values
        wave_in = wave_in < cut ? cut : wave_in
    endif
End

// return the area under the input wave with respect to a given
// baseline (and between two points)
Function Wave_integrateWRT(wave_in, baseline, [start_pt, end_pt, polarity])
    Wave wave_in
    Variable baseline
    Variable start_pt, end_pt
    String polarity

    if (ParamIsDefault(start_pt))
        start_pt = 0
    endif
    if (ParamIsDefault(end_pt))
        end_pt = Wave_getLastRowIndex(wave_in)
    endif
    if (ParamIsDefault(polarity))
        polarity = "all"
    endif

    Duplicate/FREE/O/R=[start_pt,end_pt] wave_in, wave_work
    wave_work -= baseline       // zero at baseline
    if (cmpstr(polarity, "neg") == 0 || cmpstr(polarity, "pos") == 0)
        Wave_rectifyHalf(wave_work, 0, pol=polarity)
    endif
    return area(wave_work)
End

Function Wave_getRangeBounds(wave_in, inc, waveout_name, [start_y, end_y, start_pt, end_pt])
    // Return wave with `n` x-values indicating where `wave_in`
    // crosses a value `start_y+(p*inc)` (p is a point = 0..n).
    Wave wave_in
    Variable inc
    String waveout_name
    Variable start_y, end_y
    Variable start_pt, end_pt

    // use full x range, if none specified
    if (ParamIsDefault(start_pt))
        start_pt = 0
    endif
    if (ParamIsDefault(end_pt))
        end_pt = Wave_getLastRowIndex(wave_in)
    endif
    Variable start_x = pnt2x(wave_in, start_pt)
    Variable end_x = pnt2x(wave_in, end_pt)

    // find full y range, if none specified
    WaveStats/Q/R=[start_pt, end_pt] wave_in
    if (ParamIsDefault(start_y))
        start_y = V_min
    endif
    if (ParamIsDefault(end_y))
        end_y = V_max
    endif

    // evenly divide range
    Variable npnts = ((end_y - start_y) / inc)
    npnts += 1                  // add end point
    Make/O/N=(npnts) $(waveout_name)
    Wave wave_out = $(waveout_name)

    Variable i=0
    Variable iy
    Variable ix = start_x
    for (iy=start_y; iy<end_y; iy+=inc)
        FindLevel/Q/R=(ix,end_x) wave_in, iy
        wave_out[i] = V_LevelX
        i+=1
        ix = V_LevelX
    endfor
    wave_out[i] = V_maxLoc      // add end point
End

Function/WAVE Wave_union(a, b)
    Wave a
    Wave b

    Variable a_len = Wave_getRowCount(a)
    Variable b_len = Wave_getRowCount(b)
    Variable max_len = a_len + b_len
    Make/FREE/N=(max_len) res

    res = a                     // fill result with all a values
    Variable i = 0
    Variable n = a_len
    for (i=0; i<b_len; i+=1) // fill result with new b values
        FindValue/V=(b[i]) a
        if (V_value == -1)      // novel value
            res[n] = b[i]
            n += 1
        endif
    endfor
    Redimension/N=(n) res
    Sort res, res
    return res
End

Function/WAVE Wave_intersect(a, b)
    Wave a
    Wave b

    Variable a_len = Wave_getRowCount(a)
    Variable b_len = Wave_getRowCount(b)
    Variable max_len = max(a_len, b_len)
    Make/FREE/N=(max_len) res

    Variable other_len
    if (a_len == max_len)
        Wave this = a
        Wave other = b
        other_len = b_len
    else
        Wave this = b
        Wave other = a
        other_len = a_len
    endif

    Variable n = 0
    Variable i
    for (i=0; i<other_len; i+=1)
        Variable val = other[i]
        FindValue/V=(val) this
        if (V_value != -1)
            res[n] = val
            n += 1
        endif
    endfor
    Redimension/N=(n) res
    Sort res, res
    return res
End

Function Wave_pruneNaN(wave_in, outwave_name)
    Wave wave_in
    String outwave_name
    Extract/O wave_in, $(outwave_name), (!isNaN(wave_in))
End

Function/WAVE WaveW_pruneNaN(wave_in)
    Wave wave_in
    Extract/FREE/O wave_in, res, (!isNaN(wave_in))
    return res
End

Function/WAVE Wave_indexNonNaN(wave_in)
    Wave wave_in
    Extract/FREE/INDX wave_in, res, (!isNaN(wave_in))
    return res
End

Function Wave_pruneValue(wave_in, prune_val, outwave_name)
    Wave wave_in
    Variable prune_val
    String outwave_name
    Extract/O wave_in, $(outwave_name), (wave_in != prune_val)
End

Function Wave_averageNonNaN(wave_in)
    Wave wave_in
    Extract/FREE wave_in, res, (!isNaN(wave_in))
    return mean(res)
End

Function Wave_count(wave_in, val)
    Wave wave_in
    Variable val
    Extract/FREE wave_in, res, (wave_in == val)
    return numpnts(res)
End

Function Wave_normMax(wave_in)
    Wave wave_in
    Variable wmax = WaveMax(wave_in)
    wave_in = wave_in / wmax
End

/// Returns point number where wave value changes from start point
//
// @param wave_in  wave to search
// @param start_pt (default: 0) start search from this point
// @param tol      (default: 1e-8) tolerance, value must change by more than this
// @returns point number of change, or -1 if no change found
Function Wave_findNextChange(wave_in, [start_pt, tol])
    Wave wave_in
    Variable start_pt
    Variable tol

    if (ParamIsDefault(tol))
        tol = 1e-8
    endif
    if (ParamIsDefault(start_pt))
        start_pt = 0
    endif

    Duplicate/FREE/R=[start_pt, numpnts(wave_in)] wave_in, wdiff
    Variable diff_value = wdiff[0]
    wdiff = abs(wdiff - diff_value)

    FindLevel/P/Q wdiff, abs(tol)
    if (V_flag == 1)            // no change found
        return -1
    endif
    return ceil(V_LevelX+start_pt)
End

/// Returns point number at which a consecutive run of at least `num` equal values
//
// @param wave_in  wave to search
// @param num      number of points that must be equal
// @param start_pt (default: 0) start search from this point
// @param tol      (default: 1e-8) tolerance, value must change by more than this
// @returns point number of change, or -1 if no change found
Function Wave_findConsec(wave_in, num, [start_pt, tol])
	Wave wave_in
	Variable num
	Variable start_pt
    Variable tol

    if (ParamIsDefault(start_pt))
        start_pt = 0
    endif
    if (ParamIsDefault(tol))
        tol = 0
    endif

	Variable i
	Variable n = 1
    Variable val = wave_in[start_pt]

    for (i=start_pt+1; i<numpnts(wave_in); i+=1)
        if (abs(val - wave_in[i]) <= abs(tol))
            n += 1
        else
            n = 1
            val = wave_in[i]
        endif

        if (n == num)
            return (i - (num-1))
        endif
    endfor
    return -1
End

Function Wave_mean(wvin, pbeg, pend)
    Wave wvin
    Variable pbeg, pend
    return mean(wvin, pnt2x(wvin, pbeg), pnt2x(wvin, pend))
End

#endif
