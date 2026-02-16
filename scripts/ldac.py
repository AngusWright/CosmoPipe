###############
# @file ldac.py
# @author Douglas Applegate & Thomas Erben
# @date 27/11/2013
#
# @brief Utilities to make accessing LDAC cats easier within Python
###############

# HISTORY INFORMATION:
# ====================
#
# 01.09.2010:
# I included treatment of slices through vectorkeys in
# LDACCat.__getitem__
#
# 09.09.2010:
# I made the module more robust against the non-existence
# of necessary libraries
#
# 28.09.2010:
# Bug fix: The from ... import statement must appear on the
# top of the file.
#
# 20.11.2013:
# significant extensions to the code; first proper implementations
# of LDAC tables and LDAC catalogue objects.
#
# 25.11.2013:
# - In the LDACCat class the header of the original catalogue is
#   preserved when storing the catalogue to a file.
# - I add a method to add HISTORY keywords to the image header of
#   the catalogue
#
# 27.11.2013:
# In the LDACTable I replaced the test for an empty LDAC table. Now
# it is done by testing the data element for 'None'. Before it was
# done by the 'size' method on the HDU. It seems that this size element
# of HDU changed from a method to a simple 'int' in different pyfits
# versions. Hence it is useless for code that should be compatible
# to different versions of pyfits.
#
# 28.02.2014:
# In the LDACTable 'setitem' method we do no longer create a new table
# immediatly after a new column was added. This new table creation
# takes long for big catalogues and it leads to necessary operations
# if we add many columns without doing any operations in between. We
# therefore only update column definitions and raise a flag that this
# table needs an 'update'. The update then is done whenever necessary.
#
# 28.03.2014:
# - I corrected function '__setitem__' in LDACCat. The previous
#   implementation was untested and did not work at all!
# - I transfered Dominiks implementation of of the 'add' function in the
#   LDACTable. It enables concatenation of two tables with the same
#   keys and key types.
#
# 24.07.2015:
# - The pyfits module was replaced by the equivalent 'astrpy.io.fits'.
#   pyfits will not be supported anymore at some point in the future.
# - We substituted the depreceated astropy function 'new_table' with
#   the new BinTableHDU.from_columns. The former will no longer
#   be supported in a future version of astropy.
# - We substituted constructs such as 'self.hdu.data == None' to
#   'self.hdu.data is None' to avoid a 'FutureWarning: comparison to
#   `None` will result in an elementwise object comparison in the future.'
#   warning meesage. Although the expected future change of the '=='
#   operator would have no effect in the special cases the warning message
#   is confusing!
# - We do no longer provide detailed error messages if the numpy or astropy
#   (former pyfits) modules are missing. They are quite standard and
#   sufficiently known by now.
#
# 16.08.2015:
# - Bug fix: The LDACcat saveas function did not check whether tables
#   in the catalogue not to be updated before writing the whole catalogue
#   to a file - fixed!
# - In the LDACTable class I had to change the name of the private
#   function '__update()' to '_update()' to be able to use it within
#   the LDACCat class.
#
# 09.11.2015:
# I implemented the __delitem__ method in the LDACTable class
#
# 28.07.2016:
# I converted the script to python3.

"""
Wrapper module to work with LDAC catalogues and tables
"""



# standard-library includes:
import sys
import astropy.io.fits as aif
import numpy

class LDACCat(object):
    """
    Class to represent an LDAC catalogue
    """

    def __init__(self, cat=None):
        """
        An LDAC catalogue can be instantiated either as an empty catalogue
        or with an existing catalogue on disk.

        >>> a = ldac.LDACCat('mag.cat') # reads the catalogue 'mag.cat' into
                                        # the variable 'a'.
        """

        # The LDACCcat object contains a list of LDAC tables.  We
        # internally also keep the header of the PrimaryHDU. It is
        # reused when the catalogue is saved to a file.

        # for an empty catalogue this list is empty:
        self.ldactables = []
        self.header = None

        if cat != None:
            # read tables from a catalogue on disk:
            if type(cat) == type("a"):
                hdulist = aif.open(cat)

                for hdu in hdulist:
                    if isinstance(hdu, aif.PrimaryHDU) == True:
                        self.header = hdu.header
                    if isinstance(hdu, aif.BinTableHDU) == True:
                        self.ldactables.append(LDACTable(hdu))

    def __len__(self):
        """
        return the number of LDAC tables in this catalogue

        >>> b = len(a)  # number of LDAC tables in catalogue 'a'.
        """

        return len(self.ldactables)

    def __getitem__(self, tablename):
        """
        returns the named LDAC table. Returns 'None' if the table does
        not exist.

        Example:
        >>> b = a['OBJECTS'] # returns in 'b' the LDAC table with name
                             # 'OBJECTS' from catalogue 'a'
        """

        result = None
        for table in self.ldactables:
            if table.hdu.name == tablename:
                result = table

        return result

    def __setitem__(self, name, table):
        """
        adds or replaces an LDAC table in this catalogue

        >>> a['NEW_TABLE'] = b['OBJECTS'] # adds the new table 'NEW_TABLE' in
                                          # 'a' from table 'OBJECTS' in 'b'.
        """

        if isinstance(table, LDACTable):
            # check whether a table with name exists already:
            exists = False

            for i in range(len(self.ldactables)):
                if self.ldactables[i].hdu.name == name:
                    self.ldactables[i] = table
                    exists = True

            if exists == False:
                table.setname(name)
                self.ldactables.append(table)

    def tables(self):
        """
        returns the names of the contained LDAC tables

        >>> c = a.tables()  # gives a list of table names in catalogue 'a'
        """
        tablenames = []

        for table in self.ldactables:
            tablenames.append(table.hdu.name)

        return tablenames

    def __iter__(self):
        return self.ldactables.__iter__()

    def __contains__(self, tablename):
        """
        check whether a table with name 'tablename' is present
        in this catalogue
        """

        return tablename in self.tables()

    def __add__(a, b):
        """
        Appends table b to table a and returns a new LDAC table.
        Tables 'a' and 'b' must be identical (keys and key types).

        >>> c = a + b   # appends table b to a and saves it
                        # as a LDAC table again
        """
        # First check if both tables have the same number of
        # columns:
        if len(list(a.keys())) != len(list(b.keys())):
            print("Tables do not have the same number of columns / keywords!")
            print("First table has " + str(len(list(a.keys()))) + \
                " colums / keywords.")
            print("Second table has " + str(len(list(b.keys()))) + \
                " colums / keywords.")
            return None

        # Now let's check if all kewords from the first table are also
        # present in the second table and also at the same place!
        for i in range(len(list(a.keys()))):
            if (list(a.keys())[i] in b) == False:
                print("Key " + str(list(a.keys())[i]) + \
                    " is not present in the second table!")
                return None

        arows = a.hdu.data.shape[0]
        brows = b.hdu.data.shape[0]
        nrows = arows + brows
        hdu = aif.BinTableHDU.from_columns(a.hdu.columns, nrows=nrows)

        for i in list(a.keys()):
            hdu.data.field(i)[:arows] = a.hdu.data.field(i)
            hdu.data.field(i)[arows:] = b.hdu.data.field(i)

        hdu.header = a.hdu.header
        hdu.header.update('NAXIS2', nrows)
        hdu.columns = a.hdu.columns
        hdu.name = a.hdu.name

        return LDACTable(hdu)

    def has_table(self, tablename):
        """
        check whether a table with name 'tablename' is present
        in this catalogue

        >>> c = a.has_table('OBJECTS') # returns 'True' if a table named
                                       # 'OBJECTS' is in catalogue 'a'
        """

        return self.__contains__(tablename)

    def add_history(self, keyvalue):
        """
        add a history keyword to the header of the catalogue

        >>> a.add_history('Catalogue created on 01/02/2013')
        """

        # create an empty header if necessary
        if self.header is None:
            self.header = aif.Header()

        # just delegate the work to an astropy method:
        self.header.add_history('') # empty line for separation from other
                                    # comment/history lines
        self.header.add_history(keyvalue)

    def saveas(self, filename, clobber=False):
        """
        save the LDAC catalogue to a file.

        if clobber=True an existing file is overwritten.

        >>> a.saveas('test.cat') # saves LDAC catalogue 'a' with all its
                                 # tables to file 'test.cat'
        """

        primaryHDU = aif.PrimaryHDU(header=self.header)
        hdulist = aif.HDUList([primaryHDU])

        for table in self.ldactables:
            if table.update == 1:
                table._update()

            hdulist.append(table.hdu)

        hdulist.writeto(filename, overwrite=clobber)


class LDACTable(object):
    """
    Class to represent an LDAC table
    """

    def __init__(self, hdu=None):
        """
        An LDAC table can be instantiated either as am empty table
        or with an astropy BinaryTable HDU (existing table).
        """

        if hdu is None:
            self.hdu = aif.BinTableHDU()
            self.hdu.data = None

            # We make sure that the table has 'some' proper name:
            self.hdu.name = "DEFAULT"
        else:
            self.hdu = hdu

        self.update = 0 # does the table need an update (e.g. when
                        # new columns were added?

    def __len__(self):
        """
        return the number of table entries (objects)
        """

        if self.update == 1:
            self._update()

        # 'self.hdu.data' leads to an exception for an empty catalogue.
        # Hence we check for this first:
        try:
            if self.hdu.size() == 0:
                return 0
            else:
                return len(self.hdu.data)
        except:
            if self.hdu.size == 0:
                return 0
            else:
                return len(self.hdu.data)

    def __getitem__(self, key):
        """
        returns the contents of an existing LDAC key as numpy array

        Example:
        >>> b = a['Xpos'] # store in 'b' the contents (numpy array)
                          # of key 'Xpos' from table 'a'.
        """

        if self.update == 1:
            self._update()

        if type(key) == type(5) or \
                type(key) == type(slice(5)):
            return self.hdu.data[key]

        if type(key) == type("a"):
            # we need to deal with slices through vector keys
            # such as 'MAG_APER(2)'
            startind = key.find("(")
            endind = key.find(")")

            if startind > 0 and endind > 0:
                keyname = key[:startind]
                keyindex = int(key[startind + 1:endind]) - 1

                try:
                    return self.hdu.data.field(keyname)[:, keyindex]
                except AttributeError:
                    raise KeyError(key)
            else:
                try:
                    return self.hdu.data.field(key)
                except AttributeError:
                    raise KeyError(key)

        raise TypeError

    def __setitem__(self, key, val):
        """
        set values of an LDAC table

        a['Xpos'] = b # sets the key 'Xpos' in the table 'a' to the
                      # values in numpy array 'b'. If the key does
                      # not yet exist, it is created.
        """
        # VERY uncomplete implementation for the moment!
        # - we only treat scalars for the moment!
        # - we do not check whether the key types match
        #   when an existing key is overwritten

        # sanity checks: the column name must be a string and
        # the value arrays length must match the table data
        # dimension:
        if type(key) == type("a"):
            # The first condition applies to an empty table:
            if self.hdu.data is None or len(val) == self.hdu.data.size:
                # If necessary add a new column to the table
                if self.__contains__(key) == True:
                    # quite some things might go wrong here
                    # (same data type, etc.)

                    # The following construct of '....(key)[:]' ensures
                    # a 'deep' copy of array element which we need here:
                    self.hdu.data.field(key)[:] = val
                else:
                    # determine format for the new column:
                    colformat = ""
                    if numpy.issubdtype(val.dtype, float) == True:
                        colformat = "1E"

                    if numpy.issubdtype(val.dtype, numpy.float64) == True:
                        colformat = "1D"

                    if numpy.issubdtype(val.dtype, numpy.float32) == True:
                        colformat = "1E"

                    if numpy.issubdtype(val.dtype, int) == True:
                        colformat = "1J"

                    if numpy.issubdtype(val.dtype, str) == True:
                        colformat = str(numpy.max(numpy.char.str_len(val)))+"A"

                    # now create the new column and create a 'new' table
                    # with the old plus the new column (I did not find a
                    # way to just append a new column to an existing
                    # table!):
                    newcolumn = aif.Column(name=key, format=colformat,
                                              array=val)
                    self.hdu.columns = self.hdu.columns + \
                        aif.ColDefs([newcolumn])

                    self.update = 1

        #raise NotImplementedError

    def __delitem__(self, key):
        if self.__contains__(key):
            self.hdu.columns.del_col(key)
            self.update = 1

    def _update(self):
        # update the table if necessary:
        newtabhdu = aif.BinTableHDU.from_columns(self.hdu.columns)
        newtabhdu.name = self.hdu.name
        self.hdu = newtabhdu
        self.update = 0

    def keys(self):
        """
        returns the names of the keys contained in this table

        >>> b = a.keys() # store a list of keynames of table 'a' in
                         # 'b'.
        """

        if self.update == 1:
            self._update()

        return self.hdu.columns.names

    def __iter__(self):
        if self.update == 1:
            self._update()

        return self.hdu.data.__iter__()

    def __contains__(self, item):
        if self.update == 1:
            self._update()

        return item in list(self.keys())

    def has_key(self, key):
        """
        tests whether the table contains a certain key.

        >>> b = a.haskey('Xpos') # returns 'True' if table 'a' contains
                                 # a key with name 'Xpos'.
        """

        return self.__contains__(key)

    def filter(self, mask):
        if self.update == 1:
            self._update()

        return LDACTable(aif.BinTableHDU(data=self.hdu.data[mask],
                                          header=self.hdu.header))

    def setname(self, name):
        """
        set/change the name of the LDAC table.

        >>> a.name = 'TESTTABLE' # set/change the name of the LDAC table
                                 # in 'a' to 'TESTTABLE'.
        """

        self.hdu.name = name

    def saveas(self, filename, clobber=False):
        """
        save the LDAC table as a catalogue. The produced
        catalogue will only consist of this table!

        clobber=True overwrites an existing file with the
        new catalogue

        >>> a.saveas('table.cat') # saves the LDAC table in 'a'
                                  # to file 'table.cat'
        """

        if self.update == 1:
            self._update()

        self.hdu.writeto(filename, overwrite=clobber)


def openObjects(hdulist, table='OBJECTS'):
    tablehdu = None
    for hdu in hdulist:
        # In a regular LDAC catalogue the primary header
        # does not have an EXTNAME keyword and 'hdu.header['EXTNAME']'
        # leads to a KeyError exception which we just ignore:
        try:
            if table == hdu.header['EXTNAME']:
                tablehdu = hdu
        except KeyError:
            pass

    if tablehdu is None:
        print("Table %s not present in catalogue %s" % (table,
                                                        hdulist.filename()))
        print("Creating an empty LDAC table")

    return LDACTable(tablehdu)

def openObjectFile(filename, table='OBJECTS'):
    hdulist = aif.open(filename)
    if hdulist is None:
        return None

    return openObjects(hdulist, table)

