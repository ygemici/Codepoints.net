<?php


class UnicodePlane {

    public $name;
    public $first;
    public $last;
    protected $db;
    protected $blocks;
    protected $prev;
    protected $next;

    /**
     * create a new plane instance, optionally prefilled
     */
    public function __construct($name, $db, $r=null) {
        $this->db = $db;
        if ($r === null) {
            $query = $this->db->prepare("
                SELECT name, first, last FROM planes
                WHERE replace(replace(lower(name), '_', ''), ' ', '') = :name
                LIMIT 1");
                $query->execute(array(':name' => str_replace(array(' ', '_'), '',
                                        strtolower($name))));
            $r = $query->fetch(PDO::FETCH_ASSOC);
            $query->closeCursor();
            if ($r === false) {
                throw new Exception('No plane named ' . $name);
            }
        }
        $this->name = $r['name'];
        $this->first = $r['first'];
        $this->last = $r['last'];
    }

    /**
     * get the plane name
     */
    public function getName() {
        return $this->name;
    }

    /**
     * get all blocks belonging to this plane
     */
    public function getBlocks() {
        if ($this->blocks === null) {
            $query = $this->db->prepare("
                SELECT name, first, last FROM blocks
                WHERE first >= :first AND last <= :last");
            $query->execute(array(':first' => $this->first,
                                ':last' => $this->last));
            $r = $query->fetchAll(PDO::FETCH_ASSOC);
            $query->closeCursor();
            $this->blocks = array();
            if ($r !== false) {
                foreach ($r as $b) {
                    $this->blocks[] = new UnicodeBlock('', $this->db, $b);
                }
            }
        }
        return $this->blocks;
    }

    /**
     * get previous plane or false
     */
    public function getPrev() {
        if ($this->prev === null) {
            $query = $this->db->prepare('SELECT name, first, last
                FROM planes
                WHERE last < ?
                ORDER BY first DESC
                LIMIT 1');
            $query->execute(array($this->first));
            $r = $query->fetch(PDO::FETCH_ASSOC);
            $query->closeCursor();
            if ($r === false) {
                $this->prev = false;
            } else {
                $this->prev = new self('', $this->db, $r);
            }
        }
        return $this->prev;
    }

    /**
     * get next plane or false
     */
    public function getNext() {
        if ($this->next === null) {
            $query = $this->db->prepare('SELECT name, first, last
                FROM planes
                WHERE first > ?
                ORDER BY first ASC
                LIMIT 1');
            $query->execute(array($this->last));
            $r = $query->fetch(PDO::FETCH_ASSOC);
            $query->closeCursor();
            if ($r === false) {
                $this->next = false;
            } else {
                $this->next = new self('', $this->db, $r);
            }
        }
        return $this->next;
    }

    /**
     * get plane of a specific codepoint
     */
    public static function getForCodepoint($cp, $db=null) {
        if ($cp instanceof Codepoint) {
            $db = $cp->getDB();
            $cp = $cp->getId();
        }
        $query = $db->prepare("
            SELECT name, first, last FROM planes
             WHERE first <= :cp AND last >= :cp
             LIMIT 1");
        $query->execute(array(':cp' => $cp));
        $r = $query->fetch(PDO::FETCH_ASSOC);
        $query->closeCursor();
        if ($r === false) {
            throw new Exception('No plane contains this codepoint: ' . $cp);
        }
        return new self('', $db, $r);
    }

    /**
     * get all defined Unicode planes
     */
    public static function getAll($db) {
        $query = $db->query("SELECT * FROM planes");
        $r = $query->fetchAll(PDO::FETCH_ASSOC);
        $query->closeCursor();
        $planes = array();
        foreach ($r as $pl) {
            $planes[] = new self($pl['name'], $db, $pl);
        }
        return $planes;
    }

}


//__END__
