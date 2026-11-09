"""Differential tests against the unchanged ldac.py reference implementation."""

from contextlib import redirect_stdout
import importlib.util
import io
from pathlib import Path
import runpy
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings

from astropy.io import fits
import numpy as np


ROOT = Path(__file__).resolve().parents[1]


def load_module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ORIGINAL = load_module("ldac")
OPTIMISED = load_module("ldac_optimised")


def make_hdu(rows=7):
    values = np.arange(rows, dtype=float)
    hdu = fits.BinTableHDU.from_columns([
        fits.Column(name="ID", format="J", array=np.arange(rows, dtype=np.int32)),
        fits.Column(name="X", format="D", unit="deg", array=values),
        fits.Column(name="single", format="E", array=values.astype(np.float32)),
        fits.Column(name="VECTOR", format="3D", dim="(3)", array=np.tile(values[:, None], (1, 3))),
        fits.Column(name="TEXT", format="8A", array=np.array(["a", "bb", ""] * rows)[:rows]),
        fits.Column(name="BOOL", format="L", array=values % 2 == 0),
        fits.Column(name="COMPLEX", format="C", array=(values + 1j).astype(np.complex64)),
        fits.Column(name="SHAPED", format="6E", dim="(2,3)",
                    array=np.arange(rows * 6, dtype=np.float32).reshape(rows, 3, 2)),
        fits.Column(name="INT64", format="K", array=np.arange(rows, dtype=np.int64) + 2**40),
        fits.Column(name="SPECIAL", format="D", array=np.resize([-0., np.nan, np.inf, -np.inf], rows)),
        fits.Column(name="UNSIGNED", format="I", bzero=32768, array=values.astype(np.uint16)),
        fits.Column(name="BITS", format="5X", array=np.tile([True, False, True, False, True], (rows, 1))),
        fits.Column(name="VARIABLE", format="PJ()", array=np.array([
            np.arange(i % 3, dtype=np.int32) for i in range(rows)
        ], dtype=object)),
    ], name="OBJECTS")
    hdu.header["CUSTOM"] = ("preserve until rebuild", "custom comment")
    hdu.header.add_history("table history")
    return hdu


def capture(function):
    output = io.StringIO()
    with redirect_stdout(output), warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        try:
            value = function()
            error = None
        except Exception as exc:
            value = None
            error = (type(exc), str(exc), exc.args)
    return value, error, output.getvalue(), [(w.category, str(w.message)) for w in caught]


class EquivalenceTests(unittest.TestCase):
    def setUp(self):
        self.open_files = []
        original_open = fits.open
        def tracked_open(*args, **kwargs):
            hdulist = original_open(*args, **kwargs)
            self.open_files.append(hdulist)
            return hdulist
        patcher = patch.object(fits, "open", side_effect=tracked_open)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.addCleanup(lambda: [hdulist.close() for hdulist in self.open_files])

    def assert_value_equal(self, left, right):
        if isinstance(left, (ORIGINAL.LDACTable, OPTIMISED.LDACTable)):
            self.assert_table_equal(left, right)
        elif isinstance(left, fits.FITS_record):
            self.assertIsInstance(right, fits.FITS_record)
            for name in left.array.dtype.names:
                self.assert_value_equal(left[name], right[name])
        elif isinstance(left, np.ndarray):
            self.assertEqual(type(left), type(right))
            self.assertEqual(left.dtype, right.dtype)
            self.assertEqual(left.shape, right.shape)
            if left.dtype.names:
                for name in left.dtype.names:
                    self.assert_value_equal(left[name], right[name])
            elif left.dtype.kind == "O":
                for a, b in zip(left.flat, right.flat):
                    self.assert_value_equal(a, b)
            else:
                np.testing.assert_array_equal(left, right)
        elif isinstance(left, (list, tuple)):
            self.assertEqual(type(left), type(right))
            self.assertEqual(len(left), len(right))
            for a, b in zip(left, right):
                self.assert_value_equal(a, b)
        elif isinstance(left, (float, complex, np.floating, np.complexfloating)):
            np.testing.assert_array_equal(left, right)
        else:
            self.assertEqual(left, right)

    def assert_table_equal(self, left, right):
        self.assertEqual(left.update, right.update)
        self.assertEqual(type(left.hdu), type(right.hdu))
        self.assertEqual(left.hdu.header.tostring(), right.hdu.header.tostring())
        self.assertEqual(left.hdu.columns.names, right.hdu.columns.names)
        for a, b in zip(left.hdu.columns, right.hdu.columns):
            for attr in ("name", "format", "unit", "null", "bscale", "bzero", "disp", "dim"):
                self.assertEqual(getattr(a, attr), getattr(b, attr))
        if left.hdu.data is None:
            self.assertIsNone(right.hdu.data)
        else:
            self.assert_value_equal(left.hdu.data, right.hdu.data)
            self.assertEqual(left.hdu.data.tobytes(), right.hdu.data.tobytes())

    def assert_cat_equal(self, left, right):
        self.assertEqual(left.tables(), right.tables())
        if left.header is None:
            self.assertIsNone(right.header)
        else:
            self.assertEqual(left.header.tostring(), right.header.tostring())
        for a, b in zip(left.ldactables, right.ldactables):
            self.assert_table_equal(a, b)

    def apply_both(self, left, right, operation):
        a = capture(lambda: operation(left))
        b = capture(lambda: operation(right))
        self.assert_value_equal(a[1:], b[1:])
        self.assert_value_equal(a[0], b[0])
        if isinstance(left, ORIGINAL.LDACTable):
            self.assert_table_equal(left, right)
        else:
            self.assert_cat_equal(left, right)
        return a[0], b[0]

    def tables(self, rows=7):
        return ORIGINAL.LDACTable(make_hdu(rows)), OPTIMISED.LDACTable(make_hdu(rows))

    def test_empty_tables_and_initialisation(self):
        for rows in (None, 0, 1, 7):
            with self.subTest(rows=rows):
                if rows is None:
                    a, b = ORIGINAL.LDACTable(), OPTIMISED.LDACTable()
                else:
                    a, b = self.tables(rows)
                self.assert_table_equal(a, b)
                for operation in (len, lambda t: t.keys(), lambda t: "X" in t,
                                  lambda t: t.has_key("missing"), lambda t: list(t),
                                  lambda t: t[0], lambda t: t[:], lambda t: t["missing"]):
                    self.apply_both(a, b, operation)

    def test_legacy_size_method_and_fallback(self):
        class LegacyHDU:
            data = [1, 2, 3]
            def size(self):
                return 3
        class EmptyLegacyHDU:
            data = None
            def size(self):
                return 0
        class FailingLegacyHDU:
            data = [1, 2, 3]
            def size(self):
                raise RuntimeError("legacy size unavailable")
        for hdu_type in (LegacyHDU, EmptyLegacyHDU, FailingLegacyHDU):
            with self.subTest(hdu_type=hdu_type):
                a = capture(lambda: len(ORIGINAL.LDACTable(hdu_type())))
                b = capture(lambda: len(OPTIMISED.LDACTable(hdu_type())))
                self.assert_value_equal(a, b)

    def test_access_and_errors(self):
        a, b = self.tables()
        class StringSubclass(str):
            pass
        for key in ("X", "x", "X ", "single", "SINGLE", "TEXT", "BOOL", "COMPLEX",
                    "UNSIGNED", "BITS", "VARIABLE", "SHAPED", "SHAPED(2)", "INT64",
                    "SPECIAL", "VECTOR", "VECTOR(1)", "VECTOR(0)",
                    "VECTOR(-1)", "VECTOR(4)", "VECTOR(no)", "VECTOR(1", "VECTOR)1(",
                    "X(1)", "missing", 0, -1, 7, slice(None), slice(None, None, -1),
                    slice(1, 6, 2), True, 1.0, np.int64(1), StringSubclass("X"),
                    ["X"], np.ones(7, dtype=bool), None):
            with self.subTest(key=repr(key)):
                self.apply_both(a, b, lambda t: t[key])
        a.hdu.columns.change_name("single", "x")
        b.hdu.columns.change_name("single", "x")
        for key in ("X", "x", "x ", "X ", "missing"):
            self.apply_both(a, b, lambda t: t[key])

    def test_membership_and_mutable_names(self):
        a, b = self.tables()
        for key in ("X", "x", "X ", "VECTOR(1)", "missing", None, 1, ["X"]):
            self.apply_both(a, b, lambda t: key in t)
            self.apply_both(a, b, lambda t: t.has_key(key))
        self.assertIs(a.keys(), a.hdu.columns.names)
        self.assertIs(b.keys(), b.hdu.columns.names)
        a.hdu.columns.change_name("X", "CHANGED")
        b.hdu.columns.change_name("X", "CHANGED")
        for key in ("X", "CHANGED"):
            self.apply_both(a, b, lambda t: key in t)
            self.apply_both(a, b, lambda t: t[key])

    def test_assignment_and_deferred_rebuild(self):
        a, b = ORIGINAL.LDACTable(), OPTIMISED.LDACTable()
        for key, value in (("FIRST", np.arange(7.)), ("SECOND", np.arange(7)),
                           ("IGNORED", np.arange(3)), ("LABEL", np.array(["abc"] * 7))):
            self.apply_both(a, b, lambda t: t.__setitem__(key, value.copy()))
        self.apply_both(a, b, lambda t: t.keys())
        for trigger in (len, lambda t: t.keys(), lambda t: "NEW" in t,
                        lambda t: t["NEW"], lambda t: list(t), lambda t: t._update()):
            with self.subTest(trigger=trigger):
                a, b = self.tables()
                before_a, before_b = a.hdu, b.hdu
                values = np.arange(7, dtype=np.float64)
                self.apply_both(a, b, lambda t: t.__setitem__("NEW", values.copy()))
                self.assertIs(a.hdu, before_a)
                self.assertIs(b.hdu, before_b)
                self.assertEqual(a.update, 1)
                self.apply_both(a, b, trigger)
                self.assertIsNot(a.hdu, before_a)
                self.assertIsNot(b.hdu, before_b)
                self.assertEqual(a.update, 0)
        for dtype in (np.float64, np.float32, np.int64, np.int32, np.uint32,
                      bool, np.complex64, np.dtype(">f8"), np.dtype(">i8")):
            with self.subTest(dtype=dtype):
                a, b = self.tables()
                self.apply_both(a, b, lambda t: t.__setitem__("NEW", np.arange(7).astype(dtype)))
                self.apply_both(a, b, lambda t: t.keys())
        for key, values in (
            ("TEXT", np.array(["long string"] * 7)),
            ("NEW_TEXT", np.array(["a", "longer", "", "b", "c", "d", "e"])),
            ("X", [1.] * 7), ("X", np.arange(3)), ("NEW", np.arange(3)),
            (7, np.arange(7)), ("BOOL", np.ones(7)), ("NEW", [1.] * 7),
            ("NEW", np.ones((7, 2))),
        ):
            with self.subTest(key=key, values=repr(values)):
                a, b = self.tables()
                self.apply_both(a, b, lambda t: t.__setitem__(key, values))
                self.apply_both(a, b, lambda t: t.keys())

    def test_arrays_and_aliasing(self):
        a, b = self.tables()
        x, y = self.apply_both(a, b, lambda t: t["X"])
        self.assertTrue(np.shares_memory(x, a.hdu.data))
        self.assertTrue(np.shares_memory(y, b.hdu.data))
        x[0] = y[0] = -99.
        self.assert_table_equal(a, b)
        vector_a, vector_b = self.apply_both(a, b, lambda t: t["VECTOR(2)"])
        vector_a[1] = vector_b[1] = -11.
        self.assert_table_equal(a, b)
        self.apply_both(a, b, lambda t: t.__setitem__("NEW", np.ones(7)))
        self.apply_both(a, b, lambda t: t.keys())
        x[0] = y[0] = 123.
        self.assertEqual(a["X"][0], -99.)
        self.assertEqual(b["X"][0], -99.)
        self.assert_table_equal(a, b)

    def test_deletion_and_filters(self):
        masks = (np.array([True, False, True, False, True, False, True]),
                 np.ones(7, dtype=bool), np.zeros(7, dtype=bool),
                 np.array([3, 1, 1, 0]), slice(1, 5), slice(None, None, -1),
                 np.array([True, False]), np.array([99]), None)
        for mask in masks:
            with self.subTest(mask=repr(mask)):
                a, b = self.tables()
                self.apply_both(a, b, lambda t: t.filter(mask))
        for key in ("X", "x", "missing", "VECTOR(1)", None):
            with self.subTest(key=key):
                a, b = self.tables()
                self.apply_both(a, b, lambda t: t.__delitem__(key))
                self.apply_both(a, b, lambda t: t.keys())
        a, b = self.tables()
        for key in list(a.keys()):
            self.apply_both(a, b, lambda t: t.__delitem__(key))
        self.apply_both(a, b, len)

    def test_catalogue_names_duplicates_and_replacement(self):
        a, b = ORIGINAL.LDACCat(), OPTIMISED.LDACCat()
        for module, cat in ((ORIGINAL, a), (OPTIMISED, b)):
            cat.ldactables = [module.LDACTable(make_hdu()) for _ in range(3)]
            cat.ldactables[1].setname("OTHER")
        for key in ("OBJECTS", "OTHER", "objects", "missing", None, 3):
            self.apply_both(a, b, lambda c: c[key])
            self.apply_both(a, b, lambda c: key in c)
            self.apply_both(a, b, lambda c: c.has_table(key))
        self.assertIs(a["OBJECTS"], a.ldactables[-1])
        self.assertIs(b["OBJECTS"], b.ldactables[-1])
        replacements = [module.LDACTable(make_hdu(1)) for module in (ORIGINAL, OPTIMISED)]
        for name in ("OBJECTS", "ADDED"):
            a[name], b[name] = replacements
            self.assert_cat_equal(a, b)
            self.assertEqual(a.ldactables[0] is a.ldactables[2],
                             b.ldactables[0] is b.ldactables[2])
        a.ldactables.reverse()
        b.ldactables.reverse()
        a.ldactables[0].setname("RENAMED")
        b.ldactables[0].setname("RENAMED")
        for key in ("ADDED", "RENAMED", "OBJECTS"):
            self.apply_both(a, b, lambda c: c[key])
        self.apply_both(a, b, lambda c: c.__setitem__("ignored", 1))
        self.apply_both(a, b, lambda c: c + c)

    def test_legacy_add_errors_and_diagnostics(self):
        a, b = self.tables()
        for columns in (
            [fits.Column(name="ONLY", format="D", array=np.arange(7.))],
            [fits.Column(name=f"MISSING{i}", format="D", array=np.arange(7.))
             for i in range(len(a.keys()))],
            list(make_hdu().columns),
        ):
            right_a = ORIGINAL.LDACTable(fits.BinTableHDU.from_columns(columns))
            right_b = OPTIMISED.LDACTable(fits.BinTableHDU.from_columns(columns))
            result_a = capture(lambda: ORIGINAL.LDACCat.__add__(a, right_a))
            result_b = capture(lambda: OPTIMISED.LDACCat.__add__(b, right_b))
            self.assert_value_equal(result_a, result_b)
            self.assert_table_equal(a, b)
            self.assert_table_equal(right_a, right_b)

    def test_fits_roundtrip_byte_identical(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "catalogue.fits"
            source = Path(temp) / "source.fits"
            primary = fits.PrimaryHDU()
            primary.header["CUSTOM"] = ("primary card", "primary comment")
            primary.header.add_history("primary history")
            fits.HDUList([primary, make_hdu(), make_hdu(0)]).writeto(source)
            a, b = ORIGINAL.LDACCat(str(source)), OPTIMISED.LDACCat(str(source))
            self.assert_cat_equal(a, b)
            self.apply_both(a, b, lambda c: c.add_history("new history"))
            self.apply_both(a, b, lambda c: c["OBJECTS"].__setitem__("NEW", np.empty(0)))
            for clobber in (False, True):
                if path.exists():
                    path.unlink()
                a.saveas(path, clobber=clobber)
                expected = path.read_bytes()
                path.unlink()
                b.saveas(path, clobber=clobber)
                self.assertEqual(expected, path.read_bytes())
                self.assert_cat_equal(a, b)
            self.apply_both(a, b, lambda c: c.saveas(path))
            table_a, table_b = a.ldactables[0], b.ldactables[0]
            path.unlink()
            table_a.saveas(path)
            expected = path.read_bytes()
            path.unlink()
            table_b.saveas(path)
            self.assertEqual(expected, path.read_bytes())
            self.assert_table_equal(table_a, table_b)
            for module in (ORIGINAL, OPTIMISED):
                reopened = module.LDACCat(str(path))
                self.assertEqual(reopened.tables(), ["OBJECTS"])

    def test_open_helpers_and_constructor_contract(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "source.fits"
            fits.HDUList([fits.PrimaryHDU(), make_hdu(), make_hdu(1)]).writeto(source)
            with fits.open(source) as left, fits.open(source) as right:
                for name in ("OBJECTS", "objects", "missing", None):
                    a = capture(lambda: ORIGINAL.openObjects(left, name))
                    b = capture(lambda: OPTIMISED.openObjects(right, name))
                    self.assert_value_equal(a[1:], b[1:])
                    self.assert_value_equal(a[0], b[0])
                self.assertIs(ORIGINAL.openObjects(left).hdu, left[-1])
                self.assertIs(OPTIMISED.openObjects(right).hdu, right[-1])
            for filename in (str(source), source, None, 7, str(source) + ".missing"):
                a = capture(lambda: ORIGINAL.LDACCat(filename))
                b = capture(lambda: OPTIMISED.LDACCat(filename))
                self.assert_value_equal(a[1:], b[1:])
                if a[0] is not None:
                    self.assert_cat_equal(a[0], b[0])
            for name in ("OBJECTS", "missing"):
                a = capture(lambda: ORIGINAL.openObjectFile(source, name))
                b = capture(lambda: OPTIMISED.openObjectFile(source, name))
                self.assert_value_equal(a[1:], b[1:])
                self.assert_value_equal(a[0], b[0])

    def test_prepare_treecorr_produces_identical_fits(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "catalogue.fits"
            output = Path(temp) / "treecorr.fits"
            rng = np.random.default_rng(42)
            hdu = fits.BinTableHDU.from_columns([
                fits.Column(name="ALPHA_J2000", format="D", array=rng.uniform(200., 201., 100)),
                fits.Column(name="DELTA_J2000", format="D", array=rng.uniform(-1., 1., 100)),
                *[fits.Column(name=name, format="E", array=rng.normal(size=100).astype(np.float32))
                  for name in ("e1", "e2", "PSF_e1", "PSF_e2")],
                fits.Column(name="weight", format="E", array=rng.uniform(0., 2., 100).astype(np.float32)),
            ], name="OBJECTS")
            fits.HDUList([fits.PrimaryHDU(), hdu]).writeto(source)
            results = []
            for module in (ORIGINAL, OPTIMISED):
                with (
                    patch.dict(sys.modules, {"ldac": module}),
                    patch.object(sys, "argv", ["prepare_treecorr.py", "-i", str(source),
                                              "-o", str(output)]),
                ):
                    runpy.run_path(str(ROOT / "scripts" / "prepare_treecorr.py"),
                                   run_name="__main__")
                results.append(output.read_bytes())
            self.assertEqual(results[0], results[1])

    def test_randomised_operation_sequences(self):
        rng = np.random.default_rng(314159)
        a, b = self.tables(11)
        for step in range(150):
            key = f"COL{rng.integers(0, 8)}"
            operation = rng.integers(0, 6)
            if operation == 0:
                values = rng.normal(size=11).astype(rng.choice(["float32", "float64"]))
                action = lambda t: t.__setitem__(key, values.copy())
            elif operation == 1:
                action = lambda t: t.__delitem__(key)
            elif operation == 2:
                action = lambda t: t[key]
            elif operation == 3:
                action = lambda t: key in t
            elif operation == 4:
                action = len
            else:
                action = lambda t: t.keys()
            with self.subTest(step=step, operation=operation, key=key):
                self.apply_both(a, b, action)


if __name__ == "__main__":
    unittest.main()
